//
//  ModeDtoMapping.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import Foundation

extension ModeDTO {
    init(mode: Mode) {
        self.id = mode.id.uuidString
        self.name = mode.name
        self.temperature = mode.temperature
        self.sound = mode.sound
        self.luminosity = mode.luminosity
    }
}
