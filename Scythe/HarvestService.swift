//
//  HarvestService.swift
//  Scythe
//
//  Created by Brandon Evans on 2017-01-04.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import Foundation
import HarvestKitOSX

/// Because Timer is a Foundation type now, but this lib was made with Swift 2 😂
typealias HarvestTimer = HarvestKitOSX.Timer

internal struct Credentials {
    let subdomain: String
    let username: String
    let password: String
}

/// A HarvestService makes network requests to Harvest
internal struct HarvestService {
    private let harvestController: HarvestController

    internal init(credentials: Credentials) {
        harvestController = HarvestController(accountName: credentials.subdomain, username: credentials.username, password: credentials.password)
    }

    func verifyCredentials(_ completion: @escaping (Result<User>) -> Void) {
        harvestController.accountController.getAccountInformation { user, company, error in
            if let user = user {
                completion(.success(user))
            }
            else if let error = error {
                completion(.failure(error))
            }
            else {
                completion(.failure(HarvestError.unexpectedError))
            }
        }
    }

    /// Gets all timers for the given date
    ///
    /// - Parameters:
    ///   - date: The date to get HarvestTimers for
    ///   - completion: Called with either the HarvestTimers for the date or an Error
    func getTimers(date: Date = Date(), completion: @escaping (Result<([HarvestTimer], [HarvestKitOSX.Project])>) -> Void) {
        harvestController.timersController.getTimers(date) { timers, error in
            if let timers = timers {
                completion(Result.success(timers))
            }
            else if let error = error {
                completion(Result.failure(error))
            }
            else {
                completion(Result.failure(HarvestError.unexpectedError))
            }
        }
    }

    /// Updates or adds a timer, depending on if it has an existing identifier or not
    ///
    /// - Parameters:
    ///   - timer: The timer to update or add. This can be an existing, mutated HarvestTimer or a new one
    ///   - completion: Called with either the updated HarvestTimer or an Error
    func addOrUpdateTimer(_ timer: HarvestTimer, completion: @escaping (Result<HarvestTimer>) -> Void) {
        if timer.identifier != nil {
            updateTimer(timer, completion: completion)
        }
        else {
            addTimer(timer, completion: completion)
        }
    }

    /// Updates a timer
    ///
    /// - Parameters:
    ///   - timer: The timer to update. This must be an existing HarvestTimer with an identifier
    ///   - completion: Called with either the updated HarvestTimer or an Error
    func updateTimer(_ timer: HarvestTimer, completion: @escaping (Result<HarvestTimer>) -> Void) {
        harvestController.timersController.update(timer) { timer, error in
            if let timer = timer {
                completion(Result.success(timer))
            }
            else if let error = error {
                completion(Result.failure(error))
            }
            else {
                completion(Result.failure(HarvestError.unexpectedError))
            }
        }
    }

    /// Adds a timer
    ///
    /// - Parameters:
    ///   - timer: The timer to add
    ///   - completion: Called with either the HarvestTimer that was added or an Error
    func addTimer(_ timer: HarvestTimer, completion: @escaping (Result<HarvestTimer>) -> Void) {
        harvestController.timersController.create(timer) { timer, error in
            if let timer = timer {
                completion(Result.success(timer))
            }
            else if let error = error {
                completion(Result.failure(error))
            }
            else {
                completion(Result.failure(HarvestError.unexpectedError))
            }
        }
    }

    enum HarvestError: Error, CustomDebugStringConvertible {
        case unexpectedError

        var debugDescription: String {
            switch self {
                case .unexpectedError: return "Unexpected Error"
            }
        }

    }
}
