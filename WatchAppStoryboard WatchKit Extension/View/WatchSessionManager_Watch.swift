//
//  WatchSessionManager_Watch.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//


import Foundation
import WatchConnectivity

final class WatchSessionManager_Watch: NSObject, ObservableObject {
    static let shared = WatchSessionManager_Watch()

    @Published var currentMode: ModeDTO? = nil

    private override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Watch -> iPhone : envoi actions
    func send(action: String, modeId: String? = nil, value: Int? = nil, enabled: Bool? = nil) {
        let s = WCSession.default

        //  Debug réel
        debugWCSession()

        //  Garde-fous watchOS
        guard s.activationState == .activated else {
            print(" WCSession not activated yet")
            return
        }

        guard s.isCompanionAppInstalled else {
            print(" Companion app NOT installed (or not detected by Watch)")
            return
        }

        guard s.isReachable else {
            print(" iPhone not reachable (open the iOS app at least once)")
            return
        }

        var message: [String: Any] = [WCKeys.action: action]
        if let modeId { message[WCKeys.modeId] = modeId }
        if let value { message[WCKeys.value] = value }
        if let enabled { message[WCKeys.enabled] = enabled }

        s.sendMessage(message, replyHandler: nil) { error in
            print(" Watch send error:", error.localizedDescription)
        }
    }

    func debugWCSession() {
        let s = WCSession.default
        print("activationState:", s.activationState.rawValue)
        print("companionAppInstalled:", s.isCompanionAppInstalled)
        print("reachable:", s.isReachable)
    }
}

extension WatchSessionManager_Watch: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error { print(" WC Watch activation error:", error.localizedDescription) }
        print(" WC activated:", activationState.rawValue)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let dto = WCMessageCodec.decodeModeDTO(from: message) {
                self.currentMode = dto
            }
        }
    }
}
