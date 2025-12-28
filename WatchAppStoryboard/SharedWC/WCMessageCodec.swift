//
//  WCMessageCodec.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import Foundation

enum WCMessageCodec {

    static func encodeModeDTO(_ mode: ModeDTO) -> [String: Any] {
        do {
            let data = try JSONEncoder().encode(mode)
            return [WCKeys.currentMode: data]
        } catch {
            print(" Encode ModeDTO error:", error)
            return [:]
        }
    }

    static func decodeModeDTO(from message: [String: Any]) -> ModeDTO? {
        guard let data = message[WCKeys.currentMode] as? Data else { return nil }
        do {
            return try JSONDecoder().decode(ModeDTO.self, from: data)
        } catch {
            print(" Decode ModeDTO error:", error)
            return nil
        }
    }
}
