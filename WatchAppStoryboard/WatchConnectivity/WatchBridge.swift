//
//  WatchBridge.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import Foundation

final class WatchBridge: ObservableObject {
    static let shared = WatchBridge()
    private init() {}

    /// Bind à appeler 1 fois au lancement iOS (dans PhoneApp.onAppear)
    func bind(
        modeVM: ModeViewModel,
        handleVMProvider: @escaping () -> HandleModeViewModel?
    ) {
        let wc = WatchSessionManager_iOS.shared

        // Watch -> iPhone : sélectionner un mode
        wc.onSelectMode = { modeId in
            guard let mode = modeVM.modes.first(where: { $0.id == modeId }) else { return }

            print(" Watch selected mode:", mode.name)

            // Ici tu peux décider d'appliquer un "mode courant" si tu as une notion globale.
            // Au minimum : renvoyer l'info à la Watch pour affichage.
            wc.sendCurrentMode(ModeDTO(mode: mode))
        }

        // Watch -> iPhone : Luminosité
        wc.onSetLuminosity = { value in
            guard let handleVM = handleVMProvider() else {
                print(" No active HandleModeViewModel (luminosity ignored)")
                return
            }
            handleVM.luminosity = value
            handleVM.callLuminosityHomekit()
        }

        // Watch -> iPhone : Son
        wc.onSetSound = { value in
            guard let handleVM = handleVMProvider() else {
                print(" No active HandleModeViewModel (sound ignored)")
                return
            }
            handleVM.sound = value
            handleVM.callSoundHomekit()
        }

        // Watch -> iPhone : Température
        wc.onSetTemperature = { value in
            guard let handleVM = handleVMProvider() else {
                print(" No active HandleModeViewModel (temperature ignored)")
                return
            }
            handleVM.temperature = value
            handleVM.callTempHomekit()
        }

        // Watch -> iPhone : Auto mode
        wc.onToggleAuto = { enabled in
            guard let handleVM = handleVMProvider() else {
                print(" No active HandleModeViewModel (auto ignored)")
                return
            }
            if enabled {
                handleVM.startAutoMode()
            } else {
                handleVM.stopAutoMode()
            }
        }
    }

    /// iPhone -> Watch : utile si tu veux push quand tu changes de mode côté iPhone
    func pushCurrentModeToWatch(_ mode: Mode) {
        WatchSessionManager_iOS.shared.sendCurrentMode(ModeDTO(mode: mode))
    }
}
