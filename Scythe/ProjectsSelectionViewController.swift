//
//  ProjectsSelectionViewController.swift
//  Scythe
//
//  Created by Brandon Evans on 2017-07-23.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import Cocoa
import HarvestKitOSX

/// Used to configure which projects will be part of a Split by allowing the user to toggle each project on or off in a table view
class ProjectsSelectionViewController: NSViewController {
    @IBOutlet weak var projectsTableView: NSTableView!

    var projects: [HarvestKitOSX.Project] = []
    var split: Split?
    var splitDidChange: ((Split) -> Void)?
}

extension ProjectsSelectionViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard
            row >= 0,
            row < projects.count,
            let split = split,
            let selected = object as? Bool,
            let tableColumn = tableColumn,
            tableColumn.identifier == "selected"
        else { return }

        let project = projects[row]

        if selected {
            split.projectIdentifiers.append(project.identifier)
        }
        else if let index = split.projectIdentifiers.index(of: project.identifier) {
            split.projectIdentifiers.remove(at: index)
        }

        splitDidChange?(split)
    }
}

extension ProjectsSelectionViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return projects.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard
            row >= 0,
            row < projects.count,
            let split = split,
            let tableColumn = tableColumn
        else { return nil }

        let project = projects[row]

        switch tableColumn.identifier {
        case "selected": return split.projectIdentifiers.contains(project.identifier)
        case "project": return "\(project.code) - \(project.name)"
        default: return nil
        }
    }
}
