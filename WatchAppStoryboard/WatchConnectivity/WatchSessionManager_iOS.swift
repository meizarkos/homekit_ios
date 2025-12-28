//
//  WatchSessionManager_iOS.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import Foundation
import WatchConnectivity

/// Gère la session WC côté iPhone.
/// Reçoit les actions de la Watch et permet d'envoyer l'état courant vers la Watch.
final class WatchSessionManager_iOS: NSObject, ObservableObject {
    static let shared = WatchSessionManager_iOS()

    // Callbacks = branchement à ta logique iOS
    var onSelectMode: ((UUID) -> Void)?
    var onSetLuminosity: ((Int) -> Void)?
    var onSetSound: ((Int) -> Void)?
    var onSetTemperature: ((Int) -> Void)?
    var onToggleAuto: ((Bool) -> Void)?

    private override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// iPhone -> Watch : envoie le mode courant (à afficher sur la montre)
    func sendCurrentMode(_ mode: ModeDTO) {
        guard WCSession.default.isPaired,
              WCSession.default.isWatchAppInstalled else {
            // En simu, ces flags peuvent être capricieux, mais on tente quand même.
            // Tu peux commenter ce guard si besoin en test.
            // return
            print(" Watch not paired/installed (may be simulator). Sending anyway.")
            breakGuardAndSend(mode)
            return
        }
        breakGuardAndSend(mode)
    }

    private func breakGuardAndSend(_ mode: ModeDTO) {
        let payload = WCMessageCodec.encodeModeDTO(mode)
        WCSession.default.sendMessage(payload, replyHandler: nil) { error in
            print(" sendCurrentMode error:", error.localizedDescription)
        }
    }
}

extension WatchSessionManager_iOS: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error { print(" WC activation error:", error.localizedDescription) }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    /// Watch -> iPhone : réception des actions
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            guard let action = message[WCKeys.action] as? String else { return }

            switch action {
            case WCKeys.selectMode:
                if let modeIdStr = message[WCKeys.modeId] as? String,
                   let uuid = UUID(uuidString: modeIdStr) {
                    self.onSelectMode?(uuid)
                }

            case WCKeys.setLuminosity:
                if let value = message[WCKeys.value] as? Int {
                    self.onSetLuminosity?(value)
                }

            case WCKeys.setSound:
                if let value = message[WCKeys.value] as? Int {
                    self.onSetSound?(value)
                }

            case WCKeys.setTemperature:
                if let value = message[WCKeys.value] as? Int {
                    self.onSetTemperature?(value)
                }

            case WCKeys.toggleAuto:
                if let enabled = message[WCKeys.enabled] as? Bool {
                    self.onToggleAuto?(enabled)
                }

            default:
                break
            }
        }
    }
}
