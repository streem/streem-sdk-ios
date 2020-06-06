//  Copyright © 2018 Streem, Inc. All rights reserved.

import UIKit
import StreemKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        Streem.setBackgroundURLSession(withIdentifier: identifier, completionHandler: completionHandler)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        StreemInitializer.shared.didLaunch()
        return false    // If your app adds code to process a launch URL and/or user activity, then return true when appropriate.
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let incomingURL = userActivity.webpageURL,
            let components = NSURLComponents(url: incomingURL, resolvingAgainstBaseURL: true),
            let params = components.queryItems else {
                return false
        }

        if let inviteId = params.first(where: { $0.name == "invite" } )?.value {
            StreemInitializer.shared.didLaunch(withInviteId: inviteId)
            return true
        } else {
            print("inviteId is required")
            return false
        }
    }
    
}
