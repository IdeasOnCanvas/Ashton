//
//  AppDelegate.swift
//  Example
//
//  Created by Michael Schwarz on 18.12.17.
//  Copyright © 2017 IdeasOnCanvas GmbH. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var baseTextView: NSTextView!
    @IBOutlet weak var roundTripTextView: NSTextView!
    @IBOutlet weak var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    @IBAction func executeRoundTrip(_ sender: Any) {
        self.roundTripTextView.textStorage?.setAttributedString(self.baseTextView.textStorage!)
    }
}

