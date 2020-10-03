// Copyright © 2019 Streem, Inc. All rights reserved.

import UIKit
import StreemKit

class LoginViewController : UIViewControllerSupport {

    @IBOutlet weak var submitButton: UIBarButtonItem!
    @IBOutlet weak var companyCodeField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!

    let defaults = UserDefaults.standard

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
        
        Streem.sharedInstance.login(
            companyCode: companyCode,
            email: email,
            password: password) { [weak self] (error, details) in
                guard let details = details, error == nil else {
                    print("Error logging in: \(error?.localizedDescription ?? "unknown")")
                    showFailure()
                    return
                }
                
                print("Successfully logged in... data: \(details)")
                
                guard let self = self else { return }
                
                self.showActivityIndicator(false)
                self.defaults.set(companyCode, forKey: "companyCode")
                self.defaults.set(email, forKey: "email")
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
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
}
