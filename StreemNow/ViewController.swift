//
//  ViewController.swift
//  Streem
//
//  Created by Sean Adkinson on 07/17/2018.
//  Copyright (c) 2018 Sean Adkinson. All rights reserved.
//

import UIKit
import Streem
import StreemJob
import StreemShared
import RxSwift

class ViewController: UIViewController {

    @IBOutlet weak var identifyButton: UIBarButtonItem!
    let defaults = UserDefaults.standard
    let disposeBag = DisposeBag()
    var currentUser: User?

    override func viewDidLoad() {
        super.viewDidLoad()

        StreemSession.shared.currentUser
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { user in
                self.currentUser = user
                self.identifyButton.title = user?.name ?? "Identify"
            })
            .disposed(by: disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func startCall(_ sender: Any) {
        guard let currentUser = self.currentUser else {
            let alert = UIAlertController(title: nil, message: "You must first Identify", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Got It", style: .default))
            self.present(alert, animated: true)
            return
        }

        Streem.getRecentlyIdentifiedUsers() { users in
            let users = users.filter { $0.id != currentUser.id }
            let optionMenu = UIAlertController(title: nil, message: "Call Who?", preferredStyle: .actionSheet)
            users.forEach() { user in
                optionMenu.addAction(UIAlertAction(title: "\(user.name!)", style: .default) { alert in
                    let index = optionMenu.actions.index(of: alert)
                    let user = users[index!]
                    print("Calling user: \(user.externalUserId)")

                    let state = try? StreemStateBuilder()
                        .with(myRole: .LOCAL_CUSTOMER)
                        .with(remoteUser: user, andRole: .REMOTE_PRO)
                        .build()

                    Streem.openStreem(state!)
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
        guard self.currentUser != nil else {
            let alert = UIAlertController(title: nil, message: "You must first Identify", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Got It", style: .default))
            self.present(alert, animated: true)
            return
        }

        let state = try! StreemStateBuilder()
            .with(myRole: .LOCAL_PRO)
            .build()

        Streem.openStreem(state)
    }

}

