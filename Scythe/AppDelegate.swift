//
//  AppDelegate.swift
//  Scythe
//
//  Created by Brandon Evans on 2017-01-04.
//  Copyright © 2017 Robots and Pencils. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var credentialsViewController: CredentialsViewController?
    var timersViewController: TimersViewController?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        credentialsViewController = NSApplication.shared().windows.first?.contentViewController as? CredentialsViewController
        timersViewController = storyboard.instantiateController(withIdentifier: "TimersViewController") as? TimersViewController

        credentialsViewController?.signInHandler = { [weak self] credentials in
            let service = HarvestService(credentials: credentials)
            service.verifyCredentials { result in
                switch result {
                case .success:
                    self?.timersViewController?.service = service
                    NSApplication.shared().mainWindow?.contentViewController = self?.timersViewController
                case .failure(let error):
                    NSAlert(error: error).runModal()
                    self?.credentialsViewController?.signInButton.isEnabled = true
                }
            }
        }
        timersViewController?.signOutHandler = { [weak self] in
            NSApplication.shared().mainWindow?.contentViewController = self?.credentialsViewController
        }
    }
}
