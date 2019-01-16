//
//  IdentifyViewController.swift
//  StreemNow
//
//  Created by Sean Adkinson on 7/31/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Streem

class IdentifyViewController : UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var userIdField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var avatarUrlField: UITextField!
    @IBOutlet weak var logoutButton: UIButton!

    let defaults = UserDefaults.standard


    override func viewDidLoad() {
        let userId = defaults.string(forKey: "userId") ?? ""
        let name = defaults.string(forKey: "name") ?? ""
        let avatarUrl = defaults.string(forKey: "avatarUrl") ?? ""
        
        userIdField.text = userId
        nameField.text = name
        avatarUrlField.text = avatarUrl
        saveButton.isEnabled = bothNonEmpty(userId, name)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillHide, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(IdentifyViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!

        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == Notification.Name.UIKeyboardWillHide {
            scrollView.contentInset = UIEdgeInsets.zero
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
    }

    @objc func dismissKeyboard(){
        view.endEditing(true)
    }

    func clearIdentity() {
        defaults.removeObject(forKey: "userId")
        defaults.removeObject(forKey: "name")
        defaults.removeObject(forKey: "avatarUrl")
        
        Streem.sharedInstance.clearUser()
        
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func saveIdentity(_ sender: Any) {
        guard bothNonEmpty(userIdField.text, nameField.text) else { return }
        
        let userId = userIdField.text!
        let name = nameField.text
        let avatarUrl = avatarUrlField.text
        let expert = false
        
        Streem.sharedInstance.identify(userId: userId, expert: expert, name: name, avatarUrl: avatarUrl) { [weak self] success in
            guard let self = self else { return }
            guard success else {
                let alert = UIAlertController(title: nil, message: "Unable to save identity", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            self.defaults.set(userId, forKey: "userId")
            self.defaults.set(name, forKey: "name")
            self.defaults.set(avatarUrl, forKey: "avatarUrl")
            self.defaults.set(expert, forKey: "expert")
            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func bothNonEmpty(_ string1: String?, _ string2: String?) -> Bool {
        guard let string1 = string1, !string1.isEmpty,
            let string2 = string2, !string2.isEmpty
            else { return false }
        return true
    }
}

extension IdentifyViewController: UITextFieldDelegate {
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard textField == nameField || textField == userIdField else { return true }
        let oldText = textField.text ?? ""
        let newText = oldText.replacingCharacters(in: Range(range, in: oldText)!, with: string)
        let otherField = (textField == nameField) ? userIdField : nameField
        let otherText = otherField?.text ?? ""
        saveButton.isEnabled = bothNonEmpty(newText, otherText)
        return true
    }
}
