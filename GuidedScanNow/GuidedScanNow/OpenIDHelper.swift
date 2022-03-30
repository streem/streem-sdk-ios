// Copyright © 2021 Streem, Inc. All rights reserved.

import Foundation
import AppAuth
import StreemGuidedScanKit

// MARK: - login to Streem server via OpenID

class OpenIDHelper {
    
    private static let noCompanyAccessErrorMessage = "You do not have access to this company"
    
    // MARK: - Login
    
    static func loginViaOpenId(withCompanyCode companyCode: String,
                               clientId: String,
                               tokenEndpoint: URL,
                               authorizationEndpoint: URL,
                               appDelegate: AppDelegate,
                               presentingViewController: UIViewController,
                               completion: @escaping (_ streemIdentity: StreemIdentity?, _ errorMessage: String?) -> Void) {

        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint)
        
        guard let redirectUrl = URL(string: "pro.streem.sdk.GuidedScanNow:/oauth-callback") else {
            completion(nil, nil)
            return
        }

        let request = OIDAuthorizationRequest(configuration: configuration,
                                              clientId: clientId,
                                              clientSecret: nil,
                                              scopes: [OIDScopeOpenID, OIDScopeProfile, "offline_access"],
                                              redirectURL: redirectUrl,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)
        
        DispatchQueue.main.async {
            print("Initiating authorization request with scope: \(request.scope ?? "nil")")
            
            appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, presenting: presentingViewController) { authState, error in
                if let authState = authState {
                    print("Got authorization tokens.")
                    login(withAuthState: authState, completion: completion)
                } else {
                    print("Authorization error: \(error?.localizedDescription ?? "Unknown error")")
                    completion(nil, nil)
                }
            }
        }
    }
    
    static func login(withAuthState authState: OIDAuthState,
                      completion: @escaping (_ streemIdentity: StreemIdentity?, _ errorMessage: String?) -> Void) {

        authState.performAction { freshAccessToken, _, error in
            guard let freshAccessToken = freshAccessToken, error == nil else {
                print("Error refreshing access token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil, nil)
                return
            }
            
            print("Success refreshing access token")

            streemToken(forAccessToken: freshAccessToken) { streemToken in
                guard let streemToken = streemToken else {
                    completion(nil, nil)
                    return
                }
                
                let (userName, pictureUrl, hasCompanyCodeClaim) = userInfo(fromIdToken: authState.lastTokenResponse?.idToken)
                
                guard hasCompanyCodeClaim else {
                    completion(nil, self.noCompanyAccessErrorMessage)
                    return
                }
                
                AuthPersister.persist(authState: authState)
                
                let streemIdentity = StreemIdentity(token: streemToken, name: userName, avatarUrl: pictureUrl, isExpert: true, tokenRefresher: streemTokenRefresher(forAuthState: authState))
                
                completion(streemIdentity, nil)
            }
        }
    }
    
    private static func userInfo(fromIdToken idTokenString: String?) -> (name: String, picture: String?, hasCompanyCodeClaim: Bool) {
        var userName = UIDevice.current.name
        var userPicture: String? = nil
        var hasCompanyCodeClaim = false

        if let idTokenString = idTokenString,
           let idToken = OIDIDToken(idTokenString: idTokenString) {
            let claims = idToken.claims
            
            if let name = claims["name"] as? String {
                userName = name
            }
            
            if let picture = claims["picture"] as? String {
                userPicture = picture
            }
            
            hasCompanyCodeClaim = claims["custom:streem_company_code"] != nil
        }

        return (userName, userPicture, hasCompanyCodeClaim)
    }
    
    private static func streemTokenRefresher(forAuthState authState: OIDAuthState) -> StreemTokenRefresher {
        return { didObtainFreshStreemToken in
            authState.performAction { newAccessToken, _, error in
                guard let newAccessToken = newAccessToken, error == nil else {
                    print("Error refreshing access token: \(error?.localizedDescription ?? "Unknown error")")
                    didObtainFreshStreemToken(nil)
                    return
                }

                print("Success refreshing access token")

                streemToken(forAccessToken: newAccessToken) { streemToken in
                    didObtainFreshStreemToken(streemToken)
                }
            }
        }
    }

    private static func streemToken(forAccessToken accessToken: String, completion: @escaping (String?) -> Void) {
        Streem.sharedInstance.streemToken(forAccessToken: accessToken) { error, streemToken in
            guard error == nil, let streemToken = streemToken else {
                print("Error fetching Streem Token: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            print("Got Streem Token.")
            completion(streemToken)
        }
    }

    // MARK: - Logout
    
    static func logout(withCompanyCode companyCode: String, authState: OIDAuthState, appDelegate: AppDelegate, presentingViewController: UIViewController) {
        guard let redirectUrl = URL(string: "pro.streem.sdk.GuidedScanNow:/oauth-callback") else { return }

        // For GuidedScanNow, the app's server happens to be Streem's server.
        
        Streem.sharedInstance.getOpenIdConfiguration(forCompanyCode: companyCode) { error, clientId, tokenEndpoint, authorizationEndpoint, logoutEndpoint in
            guard error == nil,
                  let tokenEndpoint = tokenEndpoint,
                  let authorizationEndpoint = authorizationEndpoint,
                  let logoutEndpoint = logoutEndpoint,
                  let idToken = authState.lastTokenResponse?.idToken,
                  let userAgent = OIDExternalUserAgentIOS(presenting: presentingViewController)
            else { return }
            
            DispatchQueue.main.async {
                print("Logging out via OpenID")
                
                // Based on https://medium.com/@dileesha/add-single-sign-on-sso-to-your-ios-application-with-wso2-identity-server-in-easy-steps-cbbb6ef8d08
                // and https://github.com/openid/AppAuth-iOS/issues/284#issuecomment-633123609

                let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, issuer: nil, registrationEndpoint: nil, endSessionEndpoint: logoutEndpoint)
                
                let logoutRequest = OIDEndSessionRequest(configuration: configuration,
                                                         idTokenHint: idToken,
                                                         postLogoutRedirectURL: redirectUrl,
                                                         additionalParameters: nil)
                
                // Note: need to retain a strong reference to the returned object until we're done with its SFAuthenticationSession
                appDelegate.currentAuthorizationFlow = OIDAuthorizationService.present(logoutRequest, externalUserAgent: userAgent) {
                    authorizationState, error in
                    print("OpenID logout: \(error?.localizedDescription ?? "SUCCESSFUL")")
                    appDelegate.currentAuthorizationFlow?.cancel()
                    appDelegate.currentAuthorizationFlow = nil
                }
            }
        }
    }
    
}
