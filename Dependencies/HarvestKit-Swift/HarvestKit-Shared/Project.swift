//
//  Project.swift
//  HarvestKit
//
//  Created by Matthew Cheetham on 19/11/2015.
//  Copyright © 2015 Matt Cheetham. All rights reserved.
//

import Foundation

/**
A struct representation of a project in the harvest system.
*/
public struct Project {
    public struct Identifier: RawRepresentable, Hashable, Equatable {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
    }
    
    /**
     A unique identifier for this Project
     */
    public var identifier: Identifier
    
    /**
    A unique identifier that denotes which client this project belongs to
    */
    public var clientIdentifier: Int?
    
    /**
    A bool to indicate whether or not the project is active. If false, the project is archived
    */
    public var active: Bool?
    
    /**
    The name of the project
    */
    public var name: String

    public var code: String
    
    /**
    The number of hours budgeted for this project
    */
    public var budgetHours: Int?
    
    /**
    Any notes assosciated with the project
    */
    public var notes: String?

    public init(identifier: Identifier, name: String, code: String) {
        self.identifier = identifier
        self.name = name
        self.code = code
    }
    
    internal init?(dictionary: [String: AnyObject]) {
        guard let identifierInt = dictionary["id"] as? Int else { return nil }
        identifier = Identifier(rawValue: String(describing: identifierInt))

        clientIdentifier = dictionary["client_id"] as? Int
        active = dictionary["active"] as? Bool
        guard let name = dictionary["name"] as? String else { return nil }
        self.name = name

        guard let code = dictionary["code"] as? String else { return nil }
        self.code = code

        budgetHours = dictionary["budget"] as? Int
        notes = dictionary["notes"] as? String
    }
    
}

extension RawRepresentable where RawValue: Hashable {
    public var hashValue: Int { return rawValue.hashValue }
}
