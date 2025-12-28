//
//  WCKeys.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import Foundation

enum WCKeys {
    // Generic
    static let action = "action"

    // Watch -> iPhone actions
    static let selectMode = "selectMode"
    static let setLuminosity = "setLuminosity"
    static let setSound = "setSound"
    static let setTemperature = "setTemperature"
    static let toggleAuto = "toggleAuto"

    // Payload fields
    static let modeId = "modeId"
    static let value = "value"
    static let enabled = "enabled"

    // iPhone -> Watch state payload
    static let currentMode = "currentMode"
}
