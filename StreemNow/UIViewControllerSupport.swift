// Copyright © 2019 Streem, Inc. All rights reserved.

import UIKit
import Streem

class UIViewControllerSupport : UIViewController {

    @IBOutlet weak public var scrollView: UIScrollView!

    private var activityIndicatorMaskView: UIView?
    private var navigationBarTintColor: UIColor?
    private var activityIndicatorShownTime: DispatchTime?
    private let activityIndicatorMinimumDisplayInterval: TimeInterval = 0.3

    override func viewDidLoad() {
        setupKeyboardHiding()
    }
    
    private func setupKeyboardHiding() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)

        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!

        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = UIEdgeInsets.zero
        } else {
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
    }

    @objc func dismissKeyboard(){
        view.endEditing(true)
    }

    func presentAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }

    func showMenu(_ menu: UIViewController) {
        if let popoverController = menu.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        self.present(menu, animated: true)
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

            let indicator = UIActivityIndicatorView(style: .whiteLarge)
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

// https://stackoverflow.com/a/40915703/194065
func decode(jwtToken jwt: String) -> [String: Any] {
  let segments = jwt.components(separatedBy: ".")
  return decodeJWTPart(segments[1]) ?? [:]
}

func base64UrlDecode(_ value: String) -> Data? {
  var base64 = value
    .replacingOccurrences(of: "-", with: "+")
    .replacingOccurrences(of: "_", with: "/")

  let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
  let requiredLength = 4 * ceil(length / 4.0)
  let paddingLength = requiredLength - length
  if paddingLength > 0 {
    let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
    base64 = base64 + padding
  }
  return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}

func decodeJWTPart(_ value: String) -> [String: Any]? {
  guard let bodyData = base64UrlDecode(value),
    let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
      return nil
  }

  return payload
}
