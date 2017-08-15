//
//  TimerSplittingTests.swift
//  Scythe
//
//  Created by Brandon Evans on 2017-01-04.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import XCTest
import HarvestKitOSX
@testable import Scythe

extension Split {
    static let all = Split(prefix: "SPLITALL", projects: [Project.Identifier(rawValue: "1"), Project.Identifier(rawValue: "2"), Project.Identifier(rawValue: "3"), Project.Identifier(rawValue: "4")])
    static let two = Split(prefix: "SPLIT", projects: [Project.Identifier(rawValue: "1"), Project.Identifier(rawValue: "2")])
}

class TimerSplittingTests: XCTestCase {
    let configuration: SplitConfiguration = {
        var configuration = SplitConfiguration()
        configuration.splits = [.all, .two]
        return configuration
    }()

    func testSplitTimerDoesntSplitAll() {
        var timer = HarvestTimer()
        timer.projectIdentifier = "1"
        timer.hours = 4
        timer.notes = "This is what I did for three hours."

        let result = timer.split(configuration: configuration)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.hours, 4)
    }

    func testSplitTimerSplitsAll() {
        var timer = HarvestTimer()
        timer.identifier = 123456789
        timer.projectIdentifier = "2"
        timer.hours = 4
        timer.active = true
        timer.notes = "SPLITALL This is what I did for three hours."

        let result = timer.split(configuration: configuration)

        XCTAssertEqual(result.count, 4)
        for timer in result {
            XCTAssertEqual(timer.hours, 1)
            XCTAssertFalse(timer.active)
            XCTAssertEqual(timer.notes, "This is what I did for three hours.")
        }

        XCTAssertEqual(result.reduce(0) { $0.1.identifier != nil ? $0.0 + 1 : $0.0 }, 1)

        XCTAssertEqual(Set(result.flatMap { $0.projectIdentifier }), Set(["1", "2", "3", "4"]))
    }

    func testSplitTimerSplitsTwo() {
        var timer = HarvestTimer()
        timer.identifier = 123456789
        timer.projectIdentifier = "2"
        timer.hours = 4
        timer.active = true
        timer.notes = "SPLIT This is what I did for three hours."

        let result = timer.split(configuration: configuration)

        XCTAssertEqual(result.count, 2)
        for timer in result {
            XCTAssertEqual(timer.hours, 2)
            XCTAssertFalse(timer.active)
            XCTAssertEqual(timer.notes, "This is what I did for three hours.")
        }

        XCTAssertEqual(result.reduce(0) { $0.1.identifier != nil ? $0.0 + 1 : $0.0 }, 1)

        XCTAssertEqual(Set(result.flatMap { $0.projectIdentifier }), Set(["1", "2"]))
    }

    func testProjectsShouldSplit() {
        XCTAssertNil(configuration.split(forNotes: ""))
        XCTAssertNil(configuration.split(forNotes: "This is what I did for three hours."))
        XCTAssertNil(configuration.split(forNotes: "SPLITThis is what I did for three hours."))
        XCTAssertNil(configuration.split(forNotes: "SPLIT!"))
        XCTAssertNil(configuration.split(forNotes: "SPLITTALL!"))
        XCTAssertEqual(configuration.split(forNotes: "SPLITALL"), Split.all)
        XCTAssertEqual(configuration.split(forNotes: "SPLITALL "), Split.all)
        XCTAssertEqual(configuration.split(forNotes: "SPLITALL This is what I did for three hours."), Split.all)
        XCTAssertEqual(configuration.split(forNotes: "SPLIT"), Split.two)
        XCTAssertEqual(configuration.split(forNotes: "SPLIT "), Split.two)
        XCTAssertEqual(configuration.split(forNotes: "SPLIT This is what I did for three hours."), Split.two)
    }
}
