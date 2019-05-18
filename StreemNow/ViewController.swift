//
//  ViewController.swift
//  StreemNow
//
//  Created by Sean Adkinson on 07/17/2018.
//  Copyright © 2018 Streem, Inc. All rights reserved.
//

import UIKit
import Streem

class ViewController: UIViewController {
    
    var appId = "*** YOUR APP-ID GOES HERE ***"
    var appSecret = "*** YOUR APP-SECRET GOES HERE ***"
    
    private var currentUser: StreemUser?
    
    private let defaultsMeasurementUnitsKey = "measurement_units"

    @IBOutlet weak var identifyButton: UIBarButtonItem!
    @IBOutlet weak var callExpertButton: UIButton!
    @IBOutlet weak var openOnsiteButton: UIButton!
    
    let defaults = UserDefaults.standard
    let measurementUnits: [UnitLength: String] = [ .inches: "inches", .feet: "feet", .millimeters: "millimeters", .centimeters: "centimeters"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Streem.initialize(delegate: self, appId: appId, appSecret: appSecret) { [weak self] in
            guard let self = self else { return }
            Streem.sharedInstance.measurementUnitsToChooseFrom = [ .inches, .feet, .millimeters, .centimeters ]
            NotificationCenter.default.addObserver(self, selector: #selector(self.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
            self.defaultsChanged()
        }
    }
    
    @objc private func defaultsChanged() {
        if let unitString = self.defaults.string(forKey: self.defaultsMeasurementUnitsKey),
            let (unit, _) = self.measurementUnits.first(where: { $1 == unitString }) {
            Streem.sharedInstance.measurementUnit = unit
        } else {
            // First launch: no default has been set yet, so choose based on device settings.
            let usesMetricSystem = Locale.current.usesMetricSystem
            let unitString = measurementUnits[usesMetricSystem ? .centimeters : .inches]
            defaults.set(unitString, forKey: defaultsMeasurementUnitsKey)
        }
    }

    @IBAction func startCall(_ sender: Any) {
        guard currentUser?.id != nil else {
            let alert = UIAlertController(title: nil, message: "You must first Identify", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Got It", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        Streem.sharedInstance.getRecentlyIdentifiedUsers(onlyExperts: false) { users in
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

                    Streem.sharedInstance.startRemoteStreem(asRole: .LOCAL_CUSTOMER, withRemoteUserId: user.id) { success in
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

        Streem.sharedInstance.startLocalStreem() { [weak self] success in
            guard let self = self else { return }
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
    
    public func currentUserDidChange(user: StreemUser?) {
        currentUser = user
        var title = "Identify"
        if let currentUser = currentUser {
            // If currentUser is non-nil, then currentUser.name SHOULD be non-empty. Unless there's some server issue...
            if !currentUser.name.isEmpty {
                title = currentUser.name
            } else if !currentUser.id.isEmpty {
                title = currentUser.id
            }
        }
        identifyButton.title = title
    }
    
    public func measurementUnitDidChange(measurementUnit: UnitLength) {
        if let string = self.measurementUnits[measurementUnit] {
            defaults.set(string, forKey: defaultsMeasurementUnitsKey)
        }
    }
}
