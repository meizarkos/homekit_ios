//
//  ModeStoeage.swift
//  WatchAppStoryboard
//
//  Created by Hugo Arnaudeau on 21/12/2025.
//
// ModeStorage.swift
import Foundation

class ModeStorage {
    static let shared = ModeStorage()
    private let storageKey = "saved_modes"

    private init() {}

    func save(_ modes: [Mode]) {
        do {
            let data = try JSONEncoder().encode(modes)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Erreur sauvegarde modes:", error)
        }
    }

    func load() -> [Mode] {
        do {
            guard let data = UserDefaults.standard.data(forKey: storageKey) else {
                return []
            }
            return try JSONDecoder().decode([Mode].self, from: data)
        } catch {
            print("Erreur chargement modes:", error)
            return []
        }
    }
}
