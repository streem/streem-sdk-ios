//  Copyright © 2018 Streem, Inc. All rights reserved.

import UIKit
import SceneKit
import StreemGuidedScanKit

class ViewController: UIViewControllerSupport {
    
    @IBOutlet weak var loginButton: UIBarButtonItem!
    @IBOutlet weak var scanListButton: UIButton!
    @IBOutlet weak var scanButton: UIButton!

    var loggedIn = false {
        didSet {
            enableButtons(loggedIn)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableButtons(false)
        StreemInitializer.shared.delegate = self
    }
    
    @IBAction func loginTap() {
        if !loggedIn {
            self.performSegue(withIdentifier: "email-login", sender: self)
        }
        else {
            let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            optionMenu.addAction(UIAlertAction(title: "Logout", style: .destructive) { alert in
                (UIApplication.shared.delegate as? AppDelegate)?.logout()
            })
            optionMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            showMenu(optionMenu)
        }
    }
        
    @IBAction func openScanListTapped(_ sender: Any) {
        guard StreemInitializer.shared.currentUser?.streemUserId != nil else {
            presentAlert(message: "You must first login")
            return
        }
        
        // Uncomment to demonstrate appearance customizations
//        GuidedScanCustomizations.performCustomizationSetup()

        StreemGuidedScan.shared.isPhotorealismEnabled = true
        StreemGuidedScan.shared.isEditingZoomReticleEnabled = true
        StreemGuidedScan.shared.streemGuidedScanDelegate = self
        StreemGuidedScan.shared.openGuidedScanList(presenter: self, completion: {[weak self] success in
            guard !success else { return }
            self?.presentAlert(message: "Failed to open guided scan list.")
        })
    }

    @IBAction func newGuidedScanTapped(_ sender: Any) {
        guard StreemInitializer.shared.currentUser?.streemUserId != nil else {
            presentAlert(message: "You must first login")
            return
        }

        // Uncomment to demonstrate appearance customizations
//        GuidedScanCustomizations.performCustomizationSetup()
        
        StreemGuidedScan.shared.isPhotorealismEnabled = true
        StreemGuidedScan.shared.isEditingZoomReticleEnabled = true
        StreemGuidedScan.shared.streemGuidedScanDelegate = self
        StreemGuidedScan.shared.startGuidedScan(presenter: self, didBegin: {[weak self] result in
            if case let .failure(error) = result {
                self?.presentAlert(message: "Failed to start guided scan experience.", error: error)
            }
        }, didEnd: { result in
            switch result {
            case .canceled:
                print("User canceled the scan")
            case .finished(let scan):
                print("User completed scan (\(scan.id)) but chose not to view it")
            case .error(let e):
                print("Error occurred during scan: \(e)")
            case .viewed(let scan):
                print("User completed scan (\(scan.id)) and chose to view it")
            }
        })
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
            } else if !currentUser.streemUserId.isEmpty {
                title = currentUser.streemUserId
            }
        }
        else {
            loggedIn = false
        }
        
        loginButton.title = title
    }
    
    private func enableButtons(_ enable: Bool) {
        scanListButton.isEnabled = enable
        scanButton.isEnabled = enable
    }
}

extension ViewController: StreemGuidedScanDelegate {

    func guidedScanningDidEnd(result: GuidedScanResult) {
        switch result {
        case .success(let scanId):
            print("\n<--- StreemGuidedScanDelegate.guidedScanningDidEnd: Success! scanId: \(scanId)\n")
        case .error(let error):
            print("\n<--- StreemGuidedScanDelegate.guidedScanningDidEnd: Error \(error)\n")
        case .userInitiatedExit:
            print("\n<--- StreemGuidedScanDelegate.guidedScanningDidEnd: The user did that thing again.\n")
        }
    }

    func layoutEstimateDidLoad(scanId: String, layoutEstimate: StreemLayoutEstimate?) {
        print("\n<--- StreemGuidedScanDelegate.layoutEstimateDidLoad for scanId: \(scanId), layoutEstimate: \(String(describing: layoutEstimate?.areaSquareMeters))\n")
    }

    func userDidExitStreemGuidedScanKit() {
        print("\n<--- StreemGuidedScanDelegate.userDidExitStreemGuidedScanKit\n")
    }
}
