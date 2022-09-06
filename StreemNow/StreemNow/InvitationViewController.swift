// Copyright © 2019 Streem, Inc. All rights reserved.

import UIKit
import StreemKit

class InvitationViewController: UIViewControllerSupport {
    
    @IBOutlet weak var callExpertButton: UIButton!
    var invitationDetails: StreemInvitationDetails!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        callExpertButton.setTitle("Call \(invitationDetails.user.displayName) from \(invitationDetails.company.name)", for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        // Logout on going back
        if let nav = navigationController, nav.viewControllers.index(of: self) == nil {
            (UIApplication.shared.delegate as? AppDelegate)?.logout()
        }
        
        super.viewWillDisappear(animated)
    }
    
    @IBAction func startCall(_ sender: Any) {
        guard let user = invitationDetails?.user
        else { return }
        
        showActivityIndicator(true)

        let remoteUser = StreemRemoteUser(role: .REMOTE_PRO, streemUserId: user.uid)

        Streem.sharedInstance.startRemoteStreemWithUser(
            remoteUser: remoteUser,
            referenceId: invitationDetails.referenceId,
            localRole: .LOCAL_CUSTOMER
        ) { [weak self] result in
            guard let self = self else { return }
            self.showActivityIndicator(false)
            if case .failure(_) = result {
                self.presentAlert(message: "Unable to call \(user.displayName).")
                return
            }
        }
    }
}
