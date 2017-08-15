//
//  ViewController.swift
//  Scythe
//
//  Created by Brandon Evans on 2017-01-04.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import Cocoa

/// Allows the user to enter their Harvest credentials and sign in
class CredentialsViewController: NSViewController {
    @IBOutlet weak var subdomainField: NSTextField!
    @IBOutlet weak var usernameField: NSTextField!
    @IBOutlet weak var passwordField: NSSecureTextField!
    @IBOutlet weak var signInButton: NSButton!

    var signInHandler: ((Credentials) -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        signInButton.isEnabled = true
        subdomainField.stringValue = "robotsandpencils"
        passwordField.stringValue = ""
    }

    @IBAction func signIn(_ sender: Any) {
        signInButton.isEnabled = false
        signInHandler?(Credentials(
            subdomain: subdomainField.stringValue,
            username: usernameField.stringValue,
            password: passwordField.stringValue
        ))
    }
}

