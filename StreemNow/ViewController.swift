//
//  ViewController.swift
//  Streem
//
//  Copyright © 2018 Streem, Inc. All rights reserved.
//

import UIKit
import Streem

class ViewController: UIViewController {
    
    @IBOutlet weak var identifyButton: UIBarButtonItem!
    @IBOutlet weak var callExpertButton: UIButton!
    @IBOutlet weak var openOnsiteButton: UIButton!
    
    var isStartingAStreem = false {
        didSet {
            identifyButton.isEnabled = !isStartingAStreem
            callExpertButton.isEnabled = !isStartingAStreem
            openOnsiteButton.isEnabled = !isStartingAStreem
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        StreemInitializer.shared.delegate = self
    }
    
    @IBAction func startCall(_ sender: Any) {
        guard StreemInitializer.shared.currentUser?.id != nil else {
            presentAlert(message: "You must first Identify")
            return
        }

        guard !isStartingAStreem else { return }
        isStartingAStreem = true

        Streem.sharedInstance.getRecentlyIdentifiedUsers(onlyExperts: true) { [weak self] users in
            guard let self = self else { return }
            let users = users.filter { $0.id != StreemInitializer.shared.currentUser?.id }
            guard !users.isEmpty else {
                self.presentAlert(message: "Nobody else has connected recently.")
                self.isStartingAStreem = false
                return
            }
            
            let optionMenu = UIAlertController(title: nil, message: "Call Who?", preferredStyle: .actionSheet)
            users.forEach() { user in
                optionMenu.addAction(UIAlertAction(title: "\(user.name)", style: .default) { alert in
                    let index = optionMenu.actions.index(of: alert)
                    let user = users[index!]
                    
                    Streem.sharedInstance.startRemoteStreem(asRole: .LOCAL_CUSTOMER, withRemoteUserId: user.id) { success in
                        if !success {
                            self.presentAlert(message: "Unable to call \(user.name).")
                            self.isStartingAStreem = false
                            return
                        }
                        else {
                            self.isStartingAStreem = false
                        }
                    }
                })
            }
            optionMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.isStartingAStreem = false
            })

            if let popoverController = optionMenu.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }

            self.present(optionMenu, animated: true)
        }
    }

    @IBAction func startOnsite(_ sender: Any) {
        guard StreemInitializer.shared.currentUser?.id != nil else {
            presentAlert(message: "You must first Identify")
            return
        }

        guard !isStartingAStreem else { return }
        isStartingAStreem = true
        
        Streem.sharedInstance.startLocalStreem() { [weak self] success in
            guard let self = self else { return }
            if !success {
                self.presentAlert(message: "Unable to establish connection.")
                self.isStartingAStreem = false
                return
            }
            else {
                self.isStartingAStreem = false
            }
        }
    }
    
    private func presentAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}

extension ViewController: StreemInitializerDelegate {
    
    public func currentUserDidChange() {
        var title = "Identify"
        if let currentUser = StreemInitializer.shared.currentUser {
            // If currentUser is non-nil, then currentUser.name SHOULD be non-empty. Unless there's some server issue...
            if !currentUser.name.isEmpty {
                title = currentUser.name
            } else if !currentUser.id.isEmpty {
                title = currentUser.id
            }
        }
        identifyButton.title = title
    }
}
