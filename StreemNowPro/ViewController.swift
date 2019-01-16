//
//  ViewController.swift
//  StreemNow
//
//  Created by Sean Adkinson on 07/17/2018.
//  Copyright (c) 2018 Sean Adkinson. All rights reserved.
//

import UIKit
import Streem
import StreemCalls

class ViewController: UIViewController {
    
    let appId = "*** YOUR APP-ID GOES HERE ***"
    let appSecret = "*** YOUR APP-SECRET GOES HERE ***"
    
    private var currentUser: StreemUser?
    
    @IBOutlet weak var identifyButton: UIBarButtonItem!
    @IBOutlet weak var startCallButton: UIButton!
    @IBOutlet weak var openOnsiteButton: UIButton!
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Streem.initialize(delegate: self, appId: appId, appSecret: appSecret) {
            StreemCalls.initialize()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func startCall(_ sender: Any) {
        guard currentUser?.id != nil else {
            let alert = UIAlertController(title: nil, message: "You must first Identify", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Got It", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        Streem.sharedInstance.getRecentlyIdentifiedUsers(onlyExperts: true) { users in
            let users = users.filter { $0.id != self.currentUser?.id }
            guard !users.isEmpty else {
                let alert = UIAlertController(title: nil, message: "Nobody else has connected recently.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
            
            let optionMenu = UIAlertController(title: nil, message: "Call Who?", preferredStyle: .actionSheet)
            users.forEach() { user in
                optionMenu.addAction(UIAlertAction(title: "\(user.name)", style: .default) { alert in
                    let index = optionMenu.actions.index(of: alert)
                    let user = users[index!]
                    print("Calling user: \(user.id)")
                    
                    Streem.sharedInstance.startCustomerStreem(withPro: user) { success in
                        if !success {
                            let alert = UIAlertController(title: nil, message: "Unable to call \(user.name).", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .default))
                            self.present(alert, animated: true)
                            return
                        }
                    }
                })
            }
            optionMenu.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            if let popoverController = optionMenu.popoverPresentationController {
                popoverController.sourceView = self.view
                popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            self.present(optionMenu, animated: true)
        }
    }
    
    @IBAction func startOnsite(_ sender: Any) {
        guard currentUser?.id != nil else {
            let alert = UIAlertController(title: nil, message: "You must first Identify", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Got It", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        Streem.sharedInstance.startOnsiteStreem() { success in
            if !success {
                let alert = UIAlertController(title: nil, message: "Unable to establish connection.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }
        }
    }
}

extension ViewController: StreemDelegate {
    public func initializationDidFail() {
        let alert = UIAlertController(title: nil, message: "Unable to establish connection.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
        identifyButton.isEnabled = false
        startCallButton.isEnabled = false
        openOnsiteButton.isEnabled = false
    }
    
    public func currentUserDidChange(user: StreemUser?) {
        currentUser = user
        identifyButton.title = currentUser?.name ?? "Identify"
    }
}
