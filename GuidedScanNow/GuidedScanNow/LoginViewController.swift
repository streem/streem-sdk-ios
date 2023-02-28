// Copyright © 2019 Streem, Inc. All rights reserved.

import UIKit
import StreemGuidedScanKit

class LoginViewController: UIViewControllerSupport {

    @IBOutlet weak var submitButton: UIBarButtonItem!
    @IBOutlet weak var companyCodeLabel: UILabel!
    @IBOutlet weak var companyCodeField: UITextField!

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let defaults = UserDefaults.standard

    private let genericLoginErrorMessage = "Unable to log in"
    private let noCompanyAccessErrorMessage = "You do not have access to this company."

    override func viewDidLoad() {
        super.viewDidLoad()

        companyCodeField.addTarget(self, action: #selector(companyCodeChanged), for: .editingChanged)
        companyCodeField.text = defaults.string(forKey: "companyCode") ?? ""
        updateSubmitButton()
    }

    @objc func companyCodeChanged(_ textField: UITextField) {
        textField.text = textField.text?.trimmingCharacters(in: .whitespaces)
        updateSubmitButton()
    }

    private func updateSubmitButton() {
        submitButton.isEnabled = companyCodeField.text != nil && !companyCodeField.text!.isEmpty
    }

    @IBAction func submitLogin(_ sender: Any) {
        dismissKeyboard()
        showActivityIndicator(true)

        let companyCode = companyCodeField.text

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
                        self.showFailure(errorMessage)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.showActivityIndicator(false)
                        self.showFailure(errorMessage)
                    }
                }
            }
        }

    private func loginToAppServer(withCompanyCode companyCode: String?, completion: @escaping (Bool, StreemIdentity?, String?) -> Void) {
        guard let companyCode = companyCode else {
            completion(false, nil, nil)
            return
        }

        // For GuidedScanNow, the app's server happens to be Streem's server.
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
                completion(false, nil, self.noCompanyAccessErrorMessage)
            }
        }
    }

    // MARK: - login error alert

    private func showFailure(_ errorMessage: String?) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: nil, message: errorMessage ?? self.genericLoginErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
