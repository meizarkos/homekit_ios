//
//  ModelViewModel.swift
//  WatchAppStoryboard
//
//  Created by Hugo Arnaudeau on 27/11/2025.
//

import Foundation
import Combine

class ModeViewModel: ObservableObject {
    @Published var modes: [Mode] = [] {
        didSet {
            ModeStorage.shared.save(modes)
        }
    }

    init() {
        modes = ModeStorage.shared.load()
    }

    func addModes(_ mode: Mode) {
        modes.append(mode)
    }

    func deleteMode(at indexSet: IndexSet) {
        modes.remove(atOffsets: indexSet)
    }

    func updateModes(_ mode: Mode) {
        guard let index = modes.firstIndex(where: { $0.id == mode.id }) else { return }
        modes[index] = mode
    }
}
