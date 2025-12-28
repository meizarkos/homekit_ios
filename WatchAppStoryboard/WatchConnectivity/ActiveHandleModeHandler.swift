//
//  ActiveHandleModeHandler.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import Foundation

final class ActiveHandleModeHolder: ObservableObject {
    static let shared = ActiveHandleModeHolder()
    @Published var current: HandleModeViewModel? = nil
}
