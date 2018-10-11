//
//  IdentifyViewController.swift
//  StreemNow
//
//  Created by Sean Adkinson on 7/31/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import Streem
import RxSwift
import RxCocoa

class IdentifyViewController : UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var userIdField: UITextField!
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var avatarUrlField: UITextField!
    @IBOutlet weak var logoutButton: UIButton!

    let defaults = UserDefaults.standard
    let disposeBag = DisposeBag()
    let viewModel = ViewModel()

    class ViewModel {
        let userId = BehaviorSubject(value: "")
        let name = BehaviorSubject(value: "")
        let avatarUrl = BehaviorSubject<String?>(value: nil)
        var isValid: Observable<Bool>

        init () {
            isValid = Observable.combineLatest(userId.asObservable(), name.asObservable())
                { (userId, name) in
                    return userId.count > 0 && name.count > 0
                }
        }
    }


    override func viewDidLoad() {
        userIdField.text = defaults.string(forKey: "userId")
        nameField.text = defaults.string(forKey: "name")
        avatarUrlField.text = defaults.string(forKey: "avatarUrl")

        userIdField.rx.text.orEmpty
            .bind(to: viewModel.userId)
            .disposed(by: disposeBag)

        nameField.rx.text.orEmpty
            .bind(to: viewModel.name)
            .disposed(by: disposeBag)

        avatarUrlField.rx.text
            .bind(to: viewModel.avatarUrl)
            .disposed(by: disposeBag)

        viewModel.isValid
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: disposeBag)

        logoutButton.rx.tap
            .bind { self.clearIdentity() }
            .disposed(by: disposeBag)

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

        Streem.clearUser()

        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func saveIdentity(_ sender: Any) {
        let userId = try! viewModel.userId.value()
        let name = try! viewModel.name.value()
        let avatarUrl = try! viewModel.avatarUrl.value()

        Streem.identify(userId: userId, name: name, avatarUrl: avatarUrl) { user in
            self.defaults.set(userId, forKey: "userId")
            self.defaults.set(name, forKey: "name")
            self.defaults.set(avatarUrl, forKey: "avatarUrl")

            DispatchQueue.main.async {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
}
