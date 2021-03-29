// Copyright © 2019 Streem, Inc. All rights reserved.

import UIKit
import StreemKit

class LoginViewController : UIViewControllerSupport {

    @IBOutlet weak var submitButton: UIBarButtonItem!
    @IBOutlet weak var companyCodeField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.isEnabled = false
        [companyCodeField, emailField, passwordField].forEach({ $0.addTarget(self, action: #selector(editingChanged), for: .editingChanged) })

        companyCodeField.text = defaults.string(forKey: "companyCode") ?? ""
        emailField.text = defaults.string(forKey: "email") ?? ""
    }

    @IBAction func submitLogin(_ sender: Any) {
        let companyCode = companyCodeField.text!
        let email = emailField.text!
        let password = passwordField.text!
        
        dismissKeyboard()
        showActivityIndicator(true)
        
        func showFailure() {
            DispatchQueue.main.async {
                self.showActivityIndicator(false)
                let alert = UIAlertController(title: nil, message: "Unable to login", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }

        // Login to the app's server, and obtain a Streem Token (wrapped in a StreemIdentity)...
        loginToAppServer(withCompanyCode: companyCode, email: email, password: password) { [weak self] companySupportsOpenId, streemIdentity, errorMessage in
            guard let self = self else { return }

            // ...and then identify the user to Streem's server:
            if let streemIdentity = streemIdentity {
                print("Successfully logged in: \(streemIdentity)")

                Streem.sharedInstance.identify(with: streemIdentity) { success in
                    self.showActivityIndicator(false)

                    if success {
                        self.defaults.set(companyCode, forKey: "companyCode")
                        self.defaults.set(email, forKey: "email")
                       
                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        showFailure()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showActivityIndicator(false)
                    
                    if !companySupportsOpenId, self.emailField.isHidden {
                        self.showEmailAndPassword(true)
                        self.updateSubmitButton()
                    }
                    else {
                        showFailure()
                    }
                }
            }
        }
    }
    
    private func loginToAppServer(withCompanyCode companyCode: String?, email: String?, password: String?, completion: @escaping (Bool, StreemIdentity?, String?) -> Void) {
        guard let companyCode = companyCode else {
            completion(false, nil, nil)
            return
        }
        
        // For StreemNow, the app's server happens to be Streem's server.
        // So we will log the user into Streem's server, and obtain the resulting Streem Token from there.
        
        Streem.sharedInstance.getOpenIdConfiguration(forCompanyCode: companyCode) { [weak self] error, clientId, tokenEndpoint, authorizationEndpoint, logoutEndpoint in
            guard let self = self else {
                completion(false, nil, nil)
                return
            }
            
            if error == nil,
               let clientId = clientId, !clientId.isEmpty,
               let tokenEndpoint = tokenEndpoint,
               let authorizationEndpoint = authorizationEndpoint {
                
                print("Authorizing via OpenID")
                OpenIDHelper.loginViaOpenId(withCompanyCode: companyCode,
                                             clientId: clientId,
                                             tokenEndpoint: tokenEndpoint,
                                             authorizationEndpoint: authorizationEndpoint,
                                             appDelegate: self.appDelegate,
                                             presentingViewController: self) { streemIdentity, errorMessage in
                    completion(true, streemIdentity, errorMessage)
                }
            } else {
                guard let email = email, !email.isEmpty, let password = password, !password.isEmpty else {
                    completion(false, nil, nil)
                    return
                }
                
                print("Authorizing directly via email/password")
                self.loginDirectlyViaStreem(withCompanyCode: companyCode, email: email, password: password, isExpert: true) { streemIdentity in
                    completion(false, streemIdentity, nil)
                }
            }
        }
    }
    
    @objc func editingChanged(_ textField: UITextField) {
        if textField.text?.count == 1 {
            if textField.text?.first == " " {
                textField.text = ""
                return
            }
        }
        guard
            let companyCode = companyCodeField.text, !companyCode.isEmpty,
            let email = emailField.text, !email.isEmpty,
            let password = passwordField.text, !password.isEmpty
        else {
            submitButton.isEnabled = false
            return
        }
        submitButton.isEnabled = true
    }
    
    // MARK: - login to Streem with email/password
    
    private func loginDirectlyViaStreem(withCompanyCode companyCode: String,
                                        email: String,
                                        password: String,
                                        isExpert: Bool,
                                        completion: @escaping (StreemIdentity?) -> Void) {
        
        Streem.sharedInstance.login(withCompanyCode: companyCode, email: email, password: password, isExpert: isExpert) { error, identity in
            guard let identity = identity, error == nil else {
                print("Error logging in: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            completion(identity)
        }
    }

    private func showEmailAndPassword(_ shown: Bool) {
        emailField.isHidden = !shown
        passwordField.isHidden = !shown
        passwordField.text = nil
    }
    
    private func updateSubmitButton() {
        submitButton.isEnabled = [companyCodeField, emailField, passwordField].reduce(true) {
            ( $0 && ($1.isHidden || ($1.text != nil && !$1.text!.isEmpty))
            )}
    }
}
