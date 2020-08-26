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
            Streem.sharedInstance.logout()
        }
        
        super.viewWillDisappear(animated)
    }
    
    @IBAction func startCall(_ sender: Any) {
        guard let user = invitationDetails?.user,
              let companyCode = invitationDetails?.company.companyCode
        else { return }
        
        showActivityIndicator(true)
        
        Streem.sharedInstance.startRemoteStreem(
            asRole: .LOCAL_CUSTOMER,
            remoteUserId: user.uid,
            referenceId: invitationDetails.referenceId,
            companyCode: companyCode
        ) { [weak self] success in
            guard let self = self else { return }
            self.showActivityIndicator(false)
            if !success {
                self.presentAlert(message: "Unable to call \(user.displayName).")
                return
            }
        }
    }
}
