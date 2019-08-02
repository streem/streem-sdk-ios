//
//  IdentifyViewController.swift
//  StreemNow
//
//  Copyright © 2018 Streem, Inc. All rights reserved.
//

import UIKit
import Streem

class IdentifyViewController : UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var userIdField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var avatarUrlField: UITextField!
    @IBOutlet weak var expertSwitch: UISwitch!
    @IBOutlet weak var logoutButton: UIButton!
    
    private var activityIndicatorMaskView: UIView?
    private var navigationBarTintColor: UIColor?
    private var activityIndicatorShownTime: DispatchTime?
    private let activityIndicatorMinimumDisplayInterval: TimeInterval = 0.3

    let defaults = UserDefaults.standard

    override func viewDidLoad() {
        let userId = defaults.string(forKey: "userId") ?? ""
        let name = defaults.string(forKey: "name") ?? ""
        let avatarUrl = defaults.string(forKey: "avatarUrl") ?? ""

        userIdField.text = userId
        nameField.text = name
        avatarUrlField.text = avatarUrl
        expertSwitch.setOn(defaults.bool(forKey: "expert"), animated: false)
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
    
    @IBAction func clearIdentity() {
        defaults.removeObject(forKey: "userId")
        defaults.removeObject(forKey: "name")
        defaults.removeObject(forKey: "avatarUrl")
        defaults.removeObject(forKey: "expert")

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
        let expert = expertSwitch.isOn
        
        showActivityIndicator(true)

        Streem.sharedInstance.identify(userId: userId, expert: expert, name: name, avatarUrl: avatarUrl) { [weak self] success in
            guard let self = self else { return }
            self.showActivityIndicator(false)
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
    
    func showActivityIndicator(_ show: Bool) {
        if show {
            guard let navigationBar = navigationController?.navigationBar else { return }
            navigationBarTintColor = navigationBar.tintColor
            navigationBar.isUserInteractionEnabled = false
            navigationBar.tintColor = UIColor(white: 0.75, alpha: 1)

            guard activityIndicatorMaskView == nil else { return }
            let maskView = UIView()
            maskView.backgroundColor = UIColor(white: 0, alpha: 0.25)
            view.addSubview(maskView)
            maskView.translatesAutoresizingMaskIntoConstraints = false
            maskView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            maskView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
            maskView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            maskView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
            activityIndicatorMaskView = maskView

            let indicator = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
            maskView.addSubview(indicator)
            indicator.translatesAutoresizingMaskIntoConstraints = false
            indicator.centerXAnchor.constraint(equalTo: maskView.centerXAnchor).isActive = true
            indicator.centerYAnchor.constraint(equalTo: maskView.centerYAnchor).isActive = true
            indicator.startAnimating()
            
            activityIndicatorShownTime = .now()
        } else {
            guard let activityIndicatorShownTime = activityIndicatorShownTime else { return }
            DispatchQueue.main.asyncAfter(deadline: activityIndicatorShownTime + activityIndicatorMinimumDisplayInterval) { [weak self] in
                guard
                    let self = self,
                    let navigationBar = self.navigationController?.navigationBar
                else { return }
                navigationBar.isUserInteractionEnabled = true
                navigationBar.tintColor = self.navigationBarTintColor
                
                guard let maskView = self.activityIndicatorMaskView else { return }
                maskView.removeFromSuperview()
                self.activityIndicatorMaskView = nil
            }
        }
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
