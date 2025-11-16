//
//  HomeKitManager.swift
//  WatchAppStoryboard
//
//  Created by Valentin on 16/11/2025.
//


import HomeKit
import SwiftUI
import Combine

class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate {
    @Published var homes: [HMHome] = []
    var homeManager: HMHomeManager!

    override init() {
        super.init()
        homeManager = HMHomeManager()
        homeManager.delegate = self
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        homes = manager.homes
        print("Maisons disponibles : \(homes)")
    }
}
