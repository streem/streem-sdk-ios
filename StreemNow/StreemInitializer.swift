//  StreemInitializer.swift
//  Streem
//
//  Copyright © 2019 Streem, Inc. All rights reserved.

import Foundation
import Streem

protocol StreemInitializerDelegate {
    func currentUserDidChange()
}

class StreemInitializer {
    
    static let shared = StreemInitializer()
    
    var currentUser: StreemUser?
    var delegate: StreemInitializerDelegate?
    
    private let appId = "*** YOUR APP-ID GOES HERE ***"
    private let appSecret = "*** YOUR APP-SECRET GOES HERE ***"

    private let defaultsMeasurementUnitsKey = "measurement_units"
    
    private let defaults = UserDefaults.standard
    private let measurementUnits: [UnitLength: String] = [ .inches: "inches", .feet: "feet", .millimeters: "millimeters", .centimeters: "centimeters"]
    
    private init() {
        Streem.initialize(delegate: self, appId: appId, appSecret: appSecret) { [weak self] in
            guard let self = self else { return }
            Streem.sharedInstance.measurementUnitsToChooseFrom = [ .inches, .feet, .millimeters, .centimeters ]
            NotificationCenter.default.addObserver(self, selector: #selector(self.defaultsChanged), name: UserDefaults.didChangeNotification, object: nil)
            self.defaultsChanged()
        }
    }

    @objc private func defaultsChanged() {
        if let unitString = defaults.string(forKey: defaultsMeasurementUnitsKey),
            let (unit, _) = measurementUnits.first(where: { $1 == unitString }) {
            Streem.sharedInstance.measurementUnit = unit
        } else {
            // First launch: no default has been set yet, so choose based on device settings.
            let usesMetricSystem = Locale.current.usesMetricSystem
            let unitString = measurementUnits[usesMetricSystem ? .centimeters : .inches]
            defaults.set(unitString, forKey: defaultsMeasurementUnitsKey)
        }
    }
    
    func didLaunch() {
        // TODO: might use this function to signal background activation vs. fresh launch
        // For now, though, simply a way to force Streem.sharedInstance to create itself.
    }
}

extension StreemInitializer: StreemDelegate {
    
    public func currentUserDidChange(user: StreemUser?) {
        currentUser = user
        delegate?.currentUserDidChange()
    }
    
    public func measurementUnitDidChange(measurementUnit: UnitLength) {
        if let string = measurementUnits[measurementUnit] {
            defaults.set(string, forKey: defaultsMeasurementUnitsKey)
        }
    }
}
