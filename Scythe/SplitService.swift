//
//  SplitService.swift
//  Scythe
//
//  Created by Brandon Evans on 2017-07-23.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import Foundation
import HarvestKitOSX

/// A small service that loads and saves a SplitConfiguration
class SplitService {
    var configuration: SplitConfiguration?


    /// Load a SplitConfiguration from UserDefaults. If none exists, save a new empty configuration first.
    func loadConfiguration() {
        var configuration: SplitConfiguration?

        if let configurationData = UserDefaults.standard.object(forKey: "splitConfiguration") as? Data {
            configuration = NSKeyedUnarchiver.unarchiveObject(with: configurationData) as? SplitConfiguration
        }

        if configuration == nil {
            configuration = SplitConfiguration()
            UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: configuration as Any), forKey: "splitConfiguration")
        }

        self.configuration = configuration
    }

    /// Save the current SplitConfiguration to UserDefaults
    func saveConfiguration() {
        UserDefaults.standard.set(NSKeyedArchiver.archivedData(withRootObject: configuration as Any), forKey: "splitConfiguration")
    }
}

/// A set of Splits that have been configured by a user
class SplitConfiguration: NSObject, NSCoding {
    var splits: [Split] = []

    override init() {
        super.init()
    }

    func split(forNotes notes: String) -> Split? {
        return splits.first { notes == $0.prefix || notes.hasPrefix($0.prefix + " ") }
    }

    required init?(coder aDecoder: NSCoder) {
        guard let splits = aDecoder.decodeObject(forKey: "splits") as? [Split] else { return nil }
        self.splits = splits
        super.init()
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(splits, forKey: "splits")
    }
}

/// Represents a prefix that can be used in a Timer's notes to split its duration across multiple projects
class Split: NSObject, NSCoding {
    var prefix: String
    var projectIdentifiers: [Project.Identifier]

    init(prefix: String, projects: [Project.Identifier]) {
        self.prefix = prefix
        self.projectIdentifiers = projects
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        guard
            let prefix = aDecoder.decodeObject(forKey: "prefix") as? String,
            let projectStrings = aDecoder.decodeObject(forKey: "projects") as? [String]
        else { return nil }

        let projects = projectStrings.flatMap(Project.Identifier.init)
        guard projects.count == projectStrings.count else { return nil }

        self.prefix = prefix
        self.projectIdentifiers = projects
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(prefix, forKey: "prefix")
        aCoder.encode(projectIdentifiers.map { $0.rawValue }, forKey: "projects")
    }

    static func ==(lhs: Split, rhs: Split) -> Bool {
        return lhs.prefix == rhs.prefix &&
               lhs.projectIdentifiers == rhs.projectIdentifiers
    }
}

extension HarvestTimer {
    /// Split a timer according to a set of Splits, if one of the prefixes matches
    ///
    /// - Parameter configuration: The configuration containing the Splits the current user has set up
    /// - Returns: An array containing new timers if the original was split and the original timer with its time decreased to compensate
    func split(configuration: SplitConfiguration) -> [HarvestTimer] {
        guard
            let notes = notes,
            let totalHours = hours,
            let split = configuration.split(forNotes: notes)
        else { return [self] }

        let newTimerProjects = split.projectIdentifiers.filter { $0.rawValue != projectIdentifier }
        guard newTimerProjects.count > 0 else { return [self] }

        let eachHours = totalHours / Double(split.projectIdentifiers.count)
        let newNotes: String
        if notes == split.prefix {
            newNotes = ""
        }
        else {
            let range = notes.index(notes.startIndex, offsetBy: split.prefix.characters.count + 1)..<notes.endIndex
            newNotes = notes[range]
        }

        var originalTimer = self
        originalTimer.active = false
        originalTimer.hours = eachHours
        originalTimer.notes = newNotes

        let newTimers = newTimerProjects.map { project -> HarvestTimer in
            var newTimer = self
            newTimer.identifier = nil
            newTimer.active = false
            newTimer.projectIdentifier = project.rawValue
            newTimer.hours = eachHours
            newTimer.notes = newNotes
            return newTimer
        }

        return [originalTimer] + newTimers
    }
}
