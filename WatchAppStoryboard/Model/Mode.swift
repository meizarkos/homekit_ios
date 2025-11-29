//
//  Mode.swift
//  WatchAppStoryboard
//
//  Created by Hugo Arnaudeau on 26/11/2025.

import Foundation

struct Mode: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var temperature: Double
    var brightness: Double?
    var createdAt: Date = Date()
    
    init(id: UUID = UUID(), name: String, temperature: Double, brightness: Double, createdAt: Date) {
        self.id = id
        self.name = name
        self.temperature = temperature
        self.brightness = brightness
        self.createdAt = createdAt
        
    }
}

