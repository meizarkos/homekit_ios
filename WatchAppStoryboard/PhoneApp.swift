//
//  MyApp.swift
//  WatchAppStoryboard
//
//  Created by Valentin on 16/11/2025.
//


import SwiftUI

@main
struct PhoneApp: App {

    var body: some Scene {
        WindowGroup {
            HandleModeView(temp: 18, sound: 50, luminosity: 50)
                //.environmentObject(homeKitManager) //pass to everyone below
        }
    }
}
