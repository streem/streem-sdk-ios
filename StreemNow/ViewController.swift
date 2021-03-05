// Copyright © 2018 Streem, Inc. All rights reserved.

import UIKit
import StreemKit

class ViewController: UIViewControllerSupport {

    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var callExpertButton: UIButton!
    @IBOutlet weak var openOnsiteButton: UIButton!
    @IBOutlet weak var callLogButton: UIButton!

    var loggedIn = false
    var invitationDetails: StreemInvitationDetails?
    var callLogEntries: [StreemCallLogEntry]?

    override func viewDidLoad() {
        super.viewDidLoad()
        StreemInitializer.shared.delegate = self
    }

    @IBAction func loginTap() {
        if !loggedIn {
            self.performSegue(withIdentifier: "email-login", sender: self)
        }
        else {
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            optionMenu.addAction(UIAlertAction(title: "Logout", style: .destructive) { alert in
                Streem.sharedInstance.logout()
            })
            optionMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            showMenu(optionMenu)
        }
    }

    @IBAction func startCall(_ sender: Any) {
        guard StreemInitializer.shared.currentUser?.id != nil else {
            presentAlert(message: "You must first login")
            return
        }

        showActivityIndicator(true)

        Streem.sharedInstance.getRecentlyIdentifiedUsers(onlyExperts: true) { [weak self] users in
            guard let self = self else { return }
            self.showActivityIndicator(false)

            let users = users.filter { $0.id != StreemInitializer.shared.currentUser?.id }
            guard !users.isEmpty else {
                self.presentAlert(message: "Nobody else has connected recently.")
                return
            }

            let optionMenu = UIAlertController(title: nil, message: "Call Who?", preferredStyle: .actionSheet)
            users.forEach() { user in
                optionMenu.addAction(UIAlertAction(title: "\(user.name)", style: .default) { alert in
                    let index = optionMenu.actions.index(of: alert)
                    let user = users[index!]
                    self.showActivityIndicator(true)
                    print("Calling user: \(user.id)")

                    Streem.sharedInstance.startRemoteStreem(asRole: .LOCAL_CUSTOMER, withRemoteExternalUserId: user.id) { success in
                        self.showActivityIndicator(false)
                    
                        if !success {
                            self.presentAlert(message: "Unable to call \(user.name).")
                        }
                    }
                })
            }
            optionMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.showMenu(optionMenu)
        }
    }

    @IBAction func startOnsite(_ sender: Any) {
        guard StreemInitializer.shared.currentUser?.id != nil else {
            presentAlert(message: "You must first login")
            return
        }

        showActivityIndicator(true)

        Streem.sharedInstance.startLocalStreem() { [weak self] success in
            guard let self = self else { return }
            self.showActivityIndicator(false)

            if !success {
                self.presentAlert(message: "Unable to establish connection.")
            }
        }
    }
    
    @IBAction func fetchCallLog(_ sender: Any) {
        guard StreemInitializer.shared.currentUser?.id != nil else {
            presentAlert(message: "You must first login")
            return
        }

        showActivityIndicator(true)

        Streem.sharedInstance.fetchCallLog() { [weak self] callLogEntries in
            guard let self = self else { return }
            self.showActivityIndicator(false)

            if callLogEntries.isEmpty {
                self.presentAlert(message: "No call log available.")
            } else {
                self.callLogEntries = callLogEntries
                self.performSegue(withIdentifier: "call-log", sender: self)
            }
        }
    }
}

extension ViewController: StreemInitializerDelegate {

    public func currentUserDidChange() {
        var title = "Login"
        if let currentUser = StreemInitializer.shared.currentUser {
            loggedIn = true
            // If currentUser is non-nil, then currentUser.name SHOULD be non-empty. Unless there's some server issue...
            if !currentUser.name.isEmpty {
                title = currentUser.name
            } else if !currentUser.id.isEmpty {
                title = currentUser.id
            }
        }
        else {
            loggedIn = false
        }

        loginButton.title = title
    }

    func didLaunch(withInviteId inviteId: String) {
        showActivityIndicator(true)

        func showFailure() {
            DispatchQueue.main.async {
                self.showActivityIndicator(false)
                let alert = UIAlertController(title: nil, message: "Invalid Invite ID", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }

        // SSO based login coming soon!
    }

    func helpRequested() {
        print("help requested")
        DispatchQueue.main.async {
            self.presentAlertOnTopVC(message: "User has requested help")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let detailsViewController = segue.destination as? InvitationViewController {
            detailsViewController.invitationDetails = invitationDetails
        } else if let callLogViewController = segue.destination as? CallLogViewController {
            callLogViewController.callLogEntries = callLogEntries
        }
    }
}
