//
//  ProjectsSelectionViewControllerTests.swift
//  ScytheTests
//
//  Created by Brandon Evans on 2017-07-23.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import XCTest
import HarvestKitOSX
@testable import Scythe

class ProjectsSelectionViewControllerTests: XCTestCase {
    var subject: ProjectsSelectionViewController!
    var splitDidChangeSplit: Split?
    var splitDidChangeCallCount = 0

    override func setUp() {
        super.setUp()

        splitDidChangeSplit = nil
        splitDidChangeCallCount = 0

        subject = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: String(describing: ProjectsSelectionViewController.self)) as! ProjectsSelectionViewController
        subject.loadView()

        subject.projects = [
            Project(identifier: Project.Identifier(rawValue: "1"), name: "project-a", code: "1"),
            Project(identifier: Project.Identifier(rawValue: "2"), name: "project-b", code: "2")
        ]
        subject.split = Split(prefix: "SPLIT", projects: [Project.Identifier(rawValue: "1")])
        subject.splitDidChange = { [weak self] split in
            self?.splitDidChangeSplit = split
            self?.splitDidChangeCallCount += 1
        }
    }
    
    func testNumberOfRows() {
        XCTAssertEqual(subject.numberOfRows(in: subject.projectsTableView), 2)
    }

    func testSelectedValue() {
        XCTAssertEqual(subject.tableView(subject.projectsTableView, objectValueFor: NSTableColumn(identifier: "selected"), row: 0) as? Bool, true)
        XCTAssertEqual(subject.tableView(subject.projectsTableView, objectValueFor: NSTableColumn(identifier: "selected"), row: 1) as? Bool, false)
    }

    func testProjectValue() {
        XCTAssertEqual(subject.tableView(subject.projectsTableView, objectValueFor: NSTableColumn(identifier: "project"), row: 0) as? String, "1 - project-a")
        XCTAssertEqual(subject.tableView(subject.projectsTableView, objectValueFor: NSTableColumn(identifier: "project"), row: 1) as? String, "2 - project-b")
    }

    func testSettingProjectSelectedTrue() {
        subject.tableView(subject.projectsTableView, setObjectValue: true, for: NSTableColumn(identifier: "selected"), row: 1)

        XCTAssertEqual(splitDidChangeSplit!.projectIdentifiers, [
            Project.Identifier(rawValue: "1"),
            Project.Identifier(rawValue: "2")
        ])
        XCTAssertEqual(splitDidChangeCallCount, 1)
    }

    func testSettingProjectSelectedFalse() {
        subject.tableView(subject.projectsTableView, setObjectValue: false, for: NSTableColumn(identifier: "selected"), row: 0)

        XCTAssertEqual(splitDidChangeSplit!.projectIdentifiers, [])
        XCTAssertEqual(splitDidChangeCallCount, 1)
    }
}
