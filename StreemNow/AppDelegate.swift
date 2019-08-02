//
//  AppDelegate.swift
//  Streem
//
//  Copyright © 2018 Streem, Inc. All rights reserved.
//

import UIKit
import Streem

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Streem.setBackgroundURLSession(withIdentifier: identifier, completionHandler: completionHandler)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        StreemInitializer.shared.didLaunch()
        return false    // If your app adds code to process a launch URL and/or user activity, then return true when appropriate.
    }
    
}
