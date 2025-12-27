//
//  ModeDTO.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import Foundation

/// DTO = objet "réseau/transport" iPhone <-> Watch
/// On évite d'envoyer ton `Mode` complet si tu ajoutes des champs HomeKit etc.
struct ModeDTO: Codable, Equatable {
    var id: String
    var name: String
    var temperature: Int
    var sound: Int
    var luminosity: Int
}

