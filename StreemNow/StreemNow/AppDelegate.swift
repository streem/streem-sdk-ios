//  Copyright © 2018 Streem, Inc. All rights reserved.

import UIKit
import StreemKit
import AppAuth

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
        
        print("Opening app from deep link")
        
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let incomingURL = userActivity.webpageURL
        else {
            print("App opened from invalid link")
            return false
        }

        guard let linkType = Streem.parseUniversalLink(incomingURL: incomingURL) else {
            print("App opened without valid invite, details, nor share link")
            return false
        }

        switch linkType {
        case .invitation(companyCode: _, invitationCode: let invitationCode):
            StreemInitializer.shared.didLaunch(withInviteId: invitationCode)
            return true
        default:
            StreemInitializer.shared.didLaunch()
            print("Not an invitation link")
        }

        return false
    }
    
    // MARK: - OpenID authorization, via AppAuth
    
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
      if let authorizationFlow = currentAuthorizationFlow,
         authorizationFlow.resumeExternalUserAgentFlow(with: url) {
        currentAuthorizationFlow = nil
        return true
      }

      return false
    }
    
    func logout() {
        currentAuthorizationFlow?.cancel()
        currentAuthorizationFlow = nil

        if let currentUser = StreemInitializer.shared.currentUser,
           let companyCode = currentUser.companyCode,
           let authState = AuthPersister.retrieveAuth(),
           let topViewController = UIViewControllerSupport.defaultTopViewController() {
            OpenIDHelper.logout(withCompanyCode: companyCode, authState: authState, appDelegate: self, presentingViewController: topViewController)
        }
        
        AuthPersister.clearAuth()
    }

    
}
