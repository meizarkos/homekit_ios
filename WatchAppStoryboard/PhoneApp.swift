//
//  MyApp.swift
//  WatchAppStoryboard
//
//  Created by Valentin on 16/11/2025.
//


import SwiftUI

@main
struct PhoneApp: App {
    @StateObject var homeKitManager = HomeKitManager()

    var body: some Scene {
        WindowGroup {
            AutomaticView()
                .environmentObject(homeKitManager)
        }
    }
}
