//
//  Mode.swift
//  WatchAppStoryboard
//
//  Created by Hugo Arnaudeau on 26/11/2025.

import Foundation

struct Mode: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var temperature: Int
    var sound: Int
    var luminosity: Int

    var lightAccessoryIds: [UUID]

    init(
        id: UUID = UUID(),
        name: String,
        temperature: Int,
        sound: Int,
        luminosity: Int,
        lightAccessoryIds: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.temperature = temperature
        self.sound = sound
        self.luminosity = luminosity
        self.lightAccessoryIds = lightAccessoryIds
    }
}
