//
//  TimersViewController.swift
//  Scythe
//
//  Created by Brandon Evans on 2017-01-05.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import Cocoa
import HarvestKitOSX

/// This is the main view controller in the app. It:
/// - Loads and displays the timers for a particular date
/// - Shows which timers will be split and across which projects based on whether or not the timer notes contain a split prefix
/// - Allows the user to manage their configured splits
class TimersViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet weak var signOutButton: NSButton!
    @IBOutlet weak var splitButton: NSButton!
    @IBOutlet weak var reloadButton: NSButton!
    @IBOutlet weak var timersTableView: NSTableView!
    @IBOutlet weak var splitsTableView: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var addOrRemoveSplitButton: NSSegmentedControl!

    var service: HarvestService?
    let splitService = SplitService()
    var signOutHandler: (() -> Void)? = nil
    private var projects: [HarvestKitOSX.Project] = []
    private var timers: [HarvestTimer] = []
    private var timerViewModels: [TimerViewModel] = []
    @objc var date: NSDate = NSDate() // This property is intentionally this way to bind to the UI, don't try to make it more Swifty :)

    @IBAction func signOut(_ sender: Any) {
        signOutHandler?()
    }
    
    @IBAction func reload(_ sender: Any) {
        loadData()
    }

    @IBAction func split(_ sender: Any) {
        guard
            let service = service,
            let configuration = splitService.configuration
        else {
            let alert = NSAlert()
            alert.addButton(withTitle: "OK")
            alert.messageText = "There was an issue signing in, but this might be a bug. Please contact Brandon."
            alert.alertStyle = .warning
            alert.runModal()
            return
        }

        let timersToSplit = zip(timers, timerViewModels).filter { return $1.shouldSplit }.map { return $0.0 }
        let splitTimers = timersToSplit.flatMap { $0.split(configuration: configuration) }

        showLoading(true)

        var completedRequests = 0
        for timer in splitTimers {
            service.addOrUpdateTimer(timer) { [weak self] result in
                switch result {
                case .success: break
                case .failure(let error):
                    let alert = NSAlert(error: error)
                    alert.addButton(withTitle: "OK")
                    alert.messageText = error.localizedDescription
                    alert.informativeText = "For timer with notes: \(timer.notes ?? "")"
                    alert.alertStyle = .warning
                    alert.runModal()
                }

                completedRequests += 1
                if completedRequests == splitTimers.count {
                    self?.showLoading(false)
                }
            }
        }
    }

    @IBAction func addOrRemoveSplit(_ sender: Any) {
        guard let configuration = splitService.configuration else { return }

        switch addOrRemoveSplitButton.selectedSegment {
        case 0:
            configuration.splits.append(Split(prefix: "PREFIX", projects: []))
        case 1:
            if splitsTableView.selectedRow >= 0, splitsTableView.selectedRow < configuration.splits.count {
                configuration.splits.remove(at: splitsTableView.selectedRow)
            }
        default:
            break
        }

        splitService.saveConfiguration()
        splitsTableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        progressIndicator.usesThreadedAnimation = true
        splitService.loadConfiguration()
        splitsTableView.target = self
        splitsTableView.doubleAction = #selector(TimersViewController.handleSplitClick)
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        loadData()
    }

    func showLoading(_ loading: Bool) {
        progressIndicator.isHidden = !loading
        loading ? progressIndicator.startAnimation(nil) : progressIndicator.stopAnimation(nil)
        splitButton.isEnabled = !loading
        reloadButton.isEnabled = !loading
    }

    private var isLoading = false
    func loadData() {
        guard !isLoading else { return }
        showLoading(true)
        isLoading = true
        timersTableView.reloadData()
        splitsTableView.reloadData()
        getTimers()
    }

    private func getTimers() {
        guard let configuration = splitService.configuration else {
            splitButton.isEnabled = !timers.isEmpty
            isLoading = false
            showLoading(false)
            return
        }

        service?.getTimers(date: date as Date) { [weak self] result in
            switch result {
            case .success(let timers):
                self?.timers = timers.0
                self?.projects = timers.1
                self?.timerViewModels = timers.0.map { timer in
                    let split = configuration.split(forNotes: timer.notes ?? "")
                    return TimerViewModel(
                        shouldSplit: split != nil,
                        notes: timer.notes ?? "",
                        projects: split?.projectIdentifiers.map { $0.rawValue }.joined(separator: ", ") ?? ""
                    )
                }
                self?.timersTableView.reloadData()
                self?.splitsTableView.reloadData()
            case .failure(let error):
                let alert = NSAlert(error: error)
                alert.addButton(withTitle: "OK")
                alert.messageText = error.localizedDescription
                alert.alertStyle = .warning
                alert.runModal()
            }

            self?.splitButton.isEnabled = !(self?.timers.isEmpty ?? true)
            self?.isLoading = false
            self?.showLoading(false)
        }
    }

    func handleSplitClick() {
        guard
            splitsTableView.clickedColumn == splitsTableView.column(withIdentifier: "projects"),
            let splits = splitService.configuration?.splits
        else {
            splitsTableView.editColumn(splitsTableView.clickedColumn, row: splitsTableView.clickedRow, with: nil, select: true)
            return
        }

        let projectsSelectionViewController = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "ProjectsSelectionViewController") as! ProjectsSelectionViewController
        let index = splitsTableView.clickedRow
        projectsSelectionViewController.split = splits[index]
        projectsSelectionViewController.projects = projects
        projectsSelectionViewController.splitDidChange = { [weak self] split in
            self?.splitsTableView.reloadData()
            self?.splitService.configuration?.splits[index] = split
            self?.splitService.saveConfiguration()
        }

        let cellRect = splitsTableView.frameOfCell(atColumn: splitsTableView.clickedColumn, row: splitsTableView.clickedRow)
        presentViewController(projectsSelectionViewController, asPopoverRelativeTo: cellRect, of: splitsTableView, preferredEdge: .maxY, behavior: .transient)
    }

    // MARK: - NSTableViewDataSource, NSTableViewDelegate

    func numberOfRows(`in` tableView: NSTableView) -> Int {
        if tableView === timersTableView {
            return timerViewModels.count
        }
        else if tableView === splitsTableView {
            return splitService.configuration?.splits.count ?? 0
        }

        return 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if tableView === timersTableView {
            guard let tableColumn = tableColumn, row >= 0, row < timerViewModels.count else { return nil }
            let timerViewModel = timerViewModels[row]

            switch tableColumn.identifier {
            case "split": return timerViewModel.shouldSplit
            case "notes": return timerViewModel.notes
            case "projects": return timerViewModel.projects
            default: return nil
            }
        }
        else if tableView === splitsTableView {
            guard
                let configuration = splitService.configuration,
                let tableColumn = tableColumn,
                row >= 0,
                row < configuration.splits.count
            else { return nil }
            let split = configuration.splits[row]

            switch tableColumn.identifier {
            case "prefix": return split.prefix
            case "projects": return projects.filter { split.projectIdentifiers.contains($0.identifier) }.map { "\($0.code) - \($0.name)" }.joined(separator: ", ")
            default: return nil
            }
        }

        return nil
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, `for` tableColumn: NSTableColumn?, row: Int) {
        if tableView === timersTableView {
            guard
                let tableColumn = tableColumn,
                tableColumn.identifier == "split",
                row >= 0,
                row < timerViewModels.count,
                let shouldSplit = object as? Bool
            else { return }

            var viewModel = timerViewModels[row]
            viewModel.shouldSplit = shouldSplit
            timerViewModels[row] = viewModel
        }
        else if tableView === splitsTableView {
            guard
                let prefix = object as? String,
                let tableColumn = tableColumn,
                tableColumn == tableView.tableColumn(withIdentifier: "prefix"),
                let configuration = splitService.configuration,
                row >= 0,
                row < configuration.splits.count
            else { return }

            let split = configuration.splits[row]
            split.prefix = prefix
        }
    }
}

struct TimerViewModel {
    var shouldSplit: Bool
    let notes: String
    let projects: String
}
