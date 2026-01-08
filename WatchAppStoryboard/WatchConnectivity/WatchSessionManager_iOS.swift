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

    var onSelectMode: ((UUID) -> Void)?
    var onSetLuminosity: ((Int) -> Void)?
    var onSetSound: ((Int) -> Void)?
    var onSetTemperature: ((Int) -> Void)?
    var onToggleAuto: ((Bool) -> Void)?

    var onToggleHeartRateMode: ((Bool) -> Void)?
    var onHeartRateUpdate: ((Int) -> Void)?

    private var heartRateModeEnabled: Bool = false
    private var lastLedBrightness: Int? = nil
    private var lastHrUpdateAt: Date = .distantPast

    /// Active si tu veux logguer plus
    private let debugEnabled = false

    private override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - iPhone -> Watch : envoie le mode courant (à afficher sur la montre)
    func sendCurrentMode(_ mode: ModeDTO) {
        let payload = WCMessageCodec.encodeModeDTO(mode)

        // On tente d'envoyer même si simu / flags bizarres
        WCSession.default.sendMessage(payload, replyHandler: nil) { error in
            if self.debugEnabled {
                print(" sendCurrentMode error:", error.localizedDescription)
            }
        }
    }

    // MARK: - HR mapping (bpm -> luminosité)
    private func brightness(for bpm: Int) -> Int {
        switch bpm {
        case ..<90: return 10
        case 90..<120: return 30
        case 120..<150: return 60
        default: return 100
        }
    }

    private func setLedBrightness(_ value: Int) {
        if debugEnabled {
            print("setLedBrightness:", value)
        }
    }

    private func handleHeartRate(_ bpm: Int) {
        // throttle: max 1 update / seconde
        let now = Date()
        if now.timeIntervalSince(lastHrUpdateAt) < 1.0 { return }
        lastHrUpdateAt = now

        let newBrightness = brightness(for: bpm)

        // évite de renvoyer si inchangé
        guard newBrightness != lastLedBrightness else { return }

        setLedBrightness(newBrightness)
        lastLedBrightness = newBrightness
    }

    /// (option) quand HR mode ON : allume direct une base
    private func handleHeartRateMode(enabled: Bool) {
        heartRateModeEnabled = enabled

        if enabled {
            // allume direct une luminosité "safe" avant le 1er bpm
            setLedBrightness(30)
            lastLedBrightness = 30
        } else {
            // setLedBrightness(0)
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchSessionManager_iOS: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error, debugEnabled {
            print("WC activation error:", error.localizedDescription)
        }
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

            case WCKeys.toggleHeartRateMode:
                let enabled = (message[WCKeys.enabled] as? Bool) ?? false
                self.onToggleHeartRateMode?(enabled)
                self.handleHeartRateMode(enabled: enabled)

            case WCKeys.heartRateUpdate:
                let bpm = (message[WCKeys.bpm] as? Int)
                    ?? (message[WCKeys.value] as? Int)
                guard let bpm else { return }

                self.onHeartRateUpdate?(bpm)

                // si mode OFF, on ignore
                guard self.heartRateModeEnabled else { return }
                self.handleHeartRate(bpm)

            default:
                break
            }
        }
    }
}
