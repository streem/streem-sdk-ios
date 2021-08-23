// Copyright © 2018 Streem, Inc. All rights reserved.

import UIKit
import StreemKit

class ViewController: UIViewControllerSupport {

    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var callExpertButton: UIButton!
    @IBOutlet weak var openOnsiteButton: UIButton!
    @IBOutlet weak var callLogButton: UIButton!
    @IBOutlet weak var joinButton: UIButton!
    @IBOutlet weak var invitationTextField: UITextField!
    @IBOutlet weak var expertSwitch: UISwitch!
    
    var loggedIn = false
    var invitationDetails: StreemInvitationDetails?
    var callLogEntries: [StreemCallLogEntry]?

    override func viewDidLoad() {
        super.viewDidLoad()
        StreemInitializer.shared.delegate = self
        
        expertSwitch.isOn = false
        expertSwitch.isEnabled = false
    }

    @IBAction func loginTap() {
        if !loggedIn {
            self.performSegue(withIdentifier: "email-login", sender: self)
        }
        else {
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            optionMenu.addAction(UIAlertAction(title: "Logout", style: .destructive) { alert in
                Streem.sharedInstance.logout()
                (UIApplication.shared.delegate as? AppDelegate)?.logout()
            })
            optionMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            showMenu(optionMenu)
        }
    }

    @IBAction func startCall(_ sender: Any) {
        guard StreemInitializer.shared.currentUser?.externalUserId != nil else {
            presentAlert(message: "You must first login")
            return
        }

        showActivityIndicator(true)

        Streem.sharedInstance.getRecentlyIdentifiedUsers(onlyExperts: true) { [weak self] users in
            guard let self = self else { return }
            self.showActivityIndicator(false)

            let users = users.filter { $0.externalUserId != StreemInitializer.shared.currentUser?.externalUserId }
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
                    print("Calling user: \(user.externalUserId)")

                    Streem.sharedInstance.startRemoteStreem(asRole: .LOCAL_CUSTOMER, withRemoteExternalUserId: user.externalUserId) { success in
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
        guard StreemInitializer.shared.currentUser?.externalUserId != nil else {
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
        guard StreemInitializer.shared.currentUser?.externalUserId != nil else {
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
    
    @IBAction func invitationTextFieldReturned(_ sender: Any) {
        startCallFromInvite()
    }
    
    @IBAction func joinCallTapped(_ sender: Any) {
        if expertSwitch.isOn {
            createInvite()
        } else {
            startCallFromInvite()
        }
    }
    
    @IBAction func expertChanged(_ sender: UISwitch) {
        let expertMode = sender.isOn
        
        joinButton.setTitle(expertMode ? "Create" : "Join", for: .normal)
        invitationTextField.isEnabled = expertMode == false
        
        invitationTextField.text = ""
    }
    
    private func startCallFromInvite() {
        guard let inviteCode = invitationTextField.text?.components(separatedBy: CharacterSet.decimalDigits.inverted).joined(),
              inviteCode.count == 9
        else {
            presentAlert(message: "Please enter a valid 9 digit invitation code")
            return
        }
        showActivityIndicator(true)
        
        Streem.sharedInstance.login(withInvitationCode: inviteCode) { [weak self] error, details, identity in
            guard error == nil, let details = details, let identity = identity else {
                self?.showActivityIndicator(false)
                print("error logging in: \(error!)")
                self?.presentAlert(message: "Invalid invite code")
                return
            }
            
            Streem.sharedInstance.identify(with: identity) { [weak self] success in
                guard success else {
                    self?.showActivityIndicator(false)
                    self?.presentAlert(message: "Error Starting Call")
                    return
                }
                Streem.sharedInstance.startRemoteStreem(
                    asRole: .LOCAL_CUSTOMER,
                    remoteUserId: details.user.uid,
                    referenceId: details.referenceId,
                    companyCode: details.company.companyCode
                ) { [weak self] success in
                    self?.showActivityIndicator(false)
                    
                    if success {
                        DispatchQueue.main.async { [weak self] in
                            self?.invitationTextField.text = ""
                        }
                    } else {
                        self?.presentAlert(message: "Error Starting Call")
                    }
                }
            }
        }
        
    }
    
    func createInvite() {
        guard let currentUser = StreemInitializer.shared.currentUser else {
            presentAlert(message: "Error creating invite")
            return
        }
        
        var name = "StreemNow Invitee"
        let currentUserName = currentUser.name
        let initials = currentUserName.split(separator: " ")
            .compactMap { $0.prefix(1).uppercased() }
            .reduce("") { "\($0)\($1)" }
        name += " (\(initials))"

        showActivityIndicator(true)

        Streem.sharedInstance.createInvitation(forUser: name, referenceId: nil, type: .link) { [weak self] invitation, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.showActivityIndicator(false)
                
                if let invitation = invitation {
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else { return }
                        self.invitationTextField.text = invitation.code.formattedAsInvitationCode()
                    }
                } else {
                    self.presentAlert(message: "Error creating invitation - \(error.debugDescription)")
                }
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
            } else if !currentUser.externalUserId.isEmpty {
                title = currentUser.externalUserId
            }
            
            expertSwitch.isEnabled = currentUser.isExpert
        }
        else {
            loggedIn = false
            expertSwitch.isEnabled = false
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
