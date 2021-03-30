// Copyright © 2019 Streem, Inc. All rights reserved.

import UIKit
import StreemKit

class LoginViewController : UIViewControllerSupport {

    @IBOutlet weak var submitButton: UIBarButtonItem!
    @IBOutlet weak var companyCodeField: UITextField!

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let defaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()
        submitButton.isEnabled = false

        companyCodeField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        companyCodeField.text = defaults.string(forKey: "companyCode") ?? ""
    }

    @IBAction func submitLogin(_ sender: Any) {
        let companyCode = companyCodeField.text!
        
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
        loginToAppServer(withCompanyCode: companyCode) { [weak self] companySupportsOpenId, streemIdentity, errorMessage in
            guard let self = self else { return }

            // ...and then identify the user to Streem's server:
            if let streemIdentity = streemIdentity {
                print("Successfully logged in: \(streemIdentity)")

                Streem.sharedInstance.identify(with: streemIdentity) { success in
                    self.showActivityIndicator(false)

                    if success {
                        self.defaults.set(companyCode, forKey: "companyCode")
                       
                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                    } else {
                        showFailure()
                    }
                }
            }
        }
    }
    
    private func loginToAppServer(withCompanyCode companyCode: String?, completion: @escaping (Bool, StreemIdentity?, String?) -> Void) {
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
                print(error)
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
        guard let companyCode = companyCodeField.text, !companyCode.isEmpty else {
            submitButton.isEnabled = false
            return
        }
        submitButton.isEnabled = true
    }

    private func updateSubmitButton() {
        submitButton.isEnabled = [companyCodeField].reduce(true) {
            ( $0 && ($1.isHidden || ($1.text != nil && !$1.text!.isEmpty)))
        }
    }
}
