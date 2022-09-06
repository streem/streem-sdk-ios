// Copyright © 2021 Streem, Inc. All rights reserved.

import Foundation
import AuthenticationServices
import AppAuth
import StreemKit

// MARK: - login to Streem server via OpenID

class OpenIDHelper {

    private static let internalErrorMessage = "Internal inconsistency."
    private static let noCompanyAccessErrorMessage = "You do not have access to this company."
    private static let authorizationErrorMessage = "Authorization error."
    private static let refreshAccessTokenErrorMessage = "Error refreshing access token."
    private static let companyRegistrationErrorMessage = "Error fetching registration response for company."
    private static let fetchStreemTokenErrorMessage = "Error fetching Streem Token."

    // MARK: - Login

    static func loginViaOpenId(withCompanyCode companyCode: String,
                               clientId: String,
                               tokenEndpoint: URL,
                               authorizationEndpoint: URL,
                               appDelegate: AppDelegate,
                               presentingViewController: UIViewController,
                               completion: @escaping (_ streemIdentity: StreemIdentity?, _ errorMessage: String?) -> Void) {

        let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint)

        guard let redirectUrl = URL(string: "pro.streem.sdk.StreemNow:/oauth-callback") else {
            completion(nil, self.internalErrorMessage)
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

            let externalAgent = OIDExternalUserAgentASWebAuthenticationSession(with: presentingViewController)
            appDelegate.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request, externalUserAgent: externalAgent) { authState, error in
                if let authState = authState {
                    print("Got authorization tokens.")
                    login(withAuthState: authState, completion: completion)
                } else {
                    print("Authorization error: \(error?.localizedDescription ?? self.authorizationErrorMessage)")
                    completion(nil, error?.localizedDescription ?? self.authorizationErrorMessage)
                }
            }
        }
    }

    static func login(withAuthState authState: OIDAuthState,
                      completion: @escaping (_ streemIdentity: StreemIdentity?, _ errorMessage: String?) -> Void) {

        authState.performAction { freshAccessToken, _, error in
            guard let freshAccessToken = freshAccessToken, error == nil else {
                print("Error refreshing access token: \(error?.localizedDescription ?? self.refreshAccessTokenErrorMessage)")
                completion(nil, error?.localizedDescription ?? self.refreshAccessTokenErrorMessage)
                return
            }

            print("Success refreshing access token")

            let (userName, pictureUrl, companyCode) = userInfo(fromIdToken: authState.lastTokenResponse?.idToken)

            Task {
                streemToken(forAccessToken: freshAccessToken, companyCode: companyCode) { streemToken in
                    guard let streemToken = streemToken else {
                        completion(nil, self.fetchStreemTokenErrorMessage)
                        return
                    }

                    AuthPersister.persist(authState: authState)

                    let streemIdentity = StreemIdentity(token: streemToken, name: userName, avatarUrl: pictureUrl, isExpert: true, companyCode: companyCode, tokenRefresher: streemTokenRefresher(forAuthState: authState))

                    completion(streemIdentity, nil)
                }
            }
        }
    }

    private static func userInfo(fromIdToken idTokenString: String?) -> (name: String, picture: String?, companyCode: String?) {
        var userName = UIDevice.current.name
        var userPicture: String?
        var userCompanyCode: String?

        if let idTokenString = idTokenString,
           let idToken = OIDIDToken(idTokenString: idTokenString) {
            let claims = idToken.claims

            if let name = claims["name"] as? String {
                userName = name
            }

            if let picture = claims["picture"] as? String {
                userPicture = picture
            }

            if let companyCode = claims["custom:streem_company_code"] as? String {
                 userCompanyCode = companyCode
             }
        }

        return (userName, userPicture, userCompanyCode)
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

                streemToken(forAccessToken: newAccessToken, companyCode: nil) { streemToken in
                    didObtainFreshStreemToken(streemToken)
                }
            }
        }
    }

    private static func streemToken(forAccessToken accessToken: String, companyCode: String?, completion: @escaping (String?) -> Void) {
        Streem.sharedInstance.streemToken(forAccessToken: accessToken, companyCode: companyCode) { error, streemToken in
            guard error == nil, let streemToken = streemToken else {
                print("Error fetching Streem Token: \(error?.localizedDescription ?? self.fetchStreemTokenErrorMessage)")
                completion(nil)
                return
            }

            print("Got Streem Token.")
            completion(streemToken)
        }
    }

    // MARK: - Logout

    static func logout(withCompanyCode companyCode: String, authState: OIDAuthState, appDelegate: AppDelegate, presentingViewController: UIViewController) {
        // The value for the redirect URL doesn't seem to matter for logging out:
        guard let redirectUrl = URL(string: "pro.streem.sdk.StreemNow:/logoutcallback") else { return }

        // For StreemNow, the app's server happens to be Streem's server.

        Streem.sharedInstance.getOpenIdConfiguration(forCompanyCode: companyCode) { error, clientId, tokenEndpoint, authorizationEndpoint, logoutEndpoint in
            guard error == nil,
                  let tokenEndpoint = tokenEndpoint,
                  let authorizationEndpoint = authorizationEndpoint,
                  let logoutEndpoint = logoutEndpoint
            else { return }

            print("Logging out via OpenID")

            // If our existing idToken has expired, logging out will produce a user-facing `invalid_id_token_hint` error.
            // So refresh our tokens before logging out.
            authState.performAction(freshTokens: { accessToken, idToken, error in
                guard error == nil, let idToken = idToken else {
                    print("Unable to refresh tokens: \(error?.localizedDescription ?? "No idToken returned")")
                    return
                }

                DispatchQueue.main.async {
                    // Based on https://medium.com/@dileesha/add-single-sign-on-sso-to-your-ios-application-with-wso2-identity-server-in-easy-steps-cbbb6ef8d08
                    // and https://github.com/openid/AppAuth-iOS/issues/284#issuecomment-633123609

                    let configuration = OIDServiceConfiguration(authorizationEndpoint: authorizationEndpoint, tokenEndpoint: tokenEndpoint, issuer: nil, registrationEndpoint: nil, endSessionEndpoint: logoutEndpoint)

                    let logoutRequest = OIDEndSessionRequest(configuration: configuration,
                                                             idTokenHint: idToken,
                                                             postLogoutRedirectURL: redirectUrl,
                                                             additionalParameters: nil)

                    let userAgent = OIDExternalUserAgentASWebAuthenticationSession(with: presentingViewController)

                    // Note: need to retain a strong reference to the returned object until we're done with its SFAuthenticationSession
                    appDelegate.currentAuthorizationFlow = OIDAuthorizationService.present(logoutRequest, externalUserAgent: userAgent) {
                        authorizationState, error in
                        print("OpenID logout: \(error?.localizedDescription ?? "SUCCESSFUL")")
                        appDelegate.currentAuthorizationFlow?.cancel()
                        appDelegate.currentAuthorizationFlow = nil
                    }
                }
            })
        }
    }

}

// MARK: - OIDExternalUserAgentASWebAuthenticationSession

// Discussions:
//    https://developer.okta.com/blog/2022/01/13/mobile-sso
//    https://github.com/openid/AppAuth-iOS/issues/402
// Code copied from:
//    https://gist.github.com/Tak783/446b4921cf0894f031eacbd641122928

class OIDExternalUserAgentASWebAuthenticationSession: NSObject, OIDExternalUserAgent {
    private let presentingViewController: UIViewController
    private var externalUserAgentFlowInProgress: Bool = false
    private var authenticationViewController: ASWebAuthenticationSession?

    private weak var session: OIDExternalUserAgentSession?

    init(with presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        super.init()
    }

    func present(_ request: OIDExternalUserAgentRequest, session: OIDExternalUserAgentSession) -> Bool {
        if externalUserAgentFlowInProgress {
            return false
        }
        guard let requestURL = request.externalUserAgentRequestURL() else {
            return false
        }
        self.externalUserAgentFlowInProgress = true
        self.session = session

        var openedUserAgent = false

        // ASWebAuthenticationSession doesn't work with guided access (Search web for "rdar://40809553")
        // Make sure that the device is not in Guided Access mode "(Settings -> General -> Accessibility -> Enable Guided Access)"
        if UIAccessibility.isGuidedAccessEnabled == false {
            let redirectScheme = request.redirectScheme()
            let authenticationViewController = ASWebAuthenticationSession(url: requestURL, callbackURLScheme: redirectScheme) { (callbackURL, error) in
                self.authenticationViewController = nil
                if let url = callbackURL {
                    self.session?.resumeExternalUserAgentFlow(with: url)
                } else {
                    let webAuthenticationError = OIDErrorUtilities.error(with: OIDErrorCode.userCanceledAuthorizationFlow,
                                                                         underlyingError: error,
                                                                         description: nil)
                    self.session?.failExternalUserAgentFlowWithError(webAuthenticationError)
                }
            }
            authenticationViewController.presentationContextProvider = self
            /// ** Key Line of code  -> `.prefersEphemeralWebBrowserSession`** allows for private browsing
            authenticationViewController.prefersEphemeralWebBrowserSession = true
            self.authenticationViewController = authenticationViewController
            openedUserAgent = authenticationViewController.start()
        } else {
            let webAuthenticationError = OIDErrorUtilities.error(with: OIDErrorCode.safariOpenError,
                                                                 underlyingError: NSError(domain: OIDGeneralErrorDomain,
                                                                                          code:
                                                                                            OIDErrorCodeOAuth.clientError.rawValue),
                                                                 description: "Device is in Guided Access mode")
            self.session?.failExternalUserAgentFlowWithError(webAuthenticationError)
        }
        return openedUserAgent
    }

    func dismiss(animated: Bool, completion: @escaping () -> Void) {
        // Ignore this call if there is no authorization flow in progress.
        if externalUserAgentFlowInProgress == false {
            completion()
        }
        cleanUp()
        if authenticationViewController != nil {
            authenticationViewController?.cancel()
            completion()
        } else {
            completion()
        }
        return
    }
}

extension OIDExternalUserAgentASWebAuthenticationSession {
    /// Sets class variables to nil. Note 'weak references i.e. session are set to nil to avoid accidentally using them while not in an authorization flow.
    func cleanUp() {
        session = nil
        authenticationViewController = nil
        externalUserAgentFlowInProgress = false
    }
}

extension OIDExternalUserAgentASWebAuthenticationSession: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return presentingViewController.view.window!
    }
}
