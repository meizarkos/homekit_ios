//
//  WatchSessionManager_Watch.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import Foundation
import WatchConnectivity
import HealthKit

final class WatchSessionManager_Watch: NSObject, ObservableObject {
    static let shared = WatchSessionManager_Watch()

    @Published var currentMode: ModeDTO? = nil

    private let healthStore = HKHealthStore()
    private var hrTimer: Timer?

    private var lastSentBpm: Int? = nil
    private var lastBpmSentAt: Date = .distantPast

    private let debugEnabled = false

    private override init() {
        super.init()
        activate()
    }

    deinit {
        stopHeartRateUpdates()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }

        requestHeartRateAuthorizationIfNeeded()

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(action: String, modeId: String? = nil, value: Int? = nil, enabled: Bool? = nil, bpm: Int? = nil) {
        if action == WCKeys.toggleHeartRateMode {
            if enabled == true {
                startHeartRateUpdates()
            } else {
                stopHeartRateUpdates()
            }
        }

        let s = WCSession.default
        if debugEnabled { debugWCSession() }

        guard s.activationState == .activated else {
            if debugEnabled { print(" WCSession not activated yet") }
            return
        }

        guard s.isCompanionAppInstalled else {
            if debugEnabled { print(" Companion app NOT installed") }
            return
        }

        guard s.isReachable else {
            if debugEnabled { print(" iPhone not reachable (open iOS app)") }
            return
        }

        var message: [String: Any] = [WCKeys.action: action]
        if let modeId { message[WCKeys.modeId] = modeId }
        if let value { message[WCKeys.value] = value }
        if let enabled { message[WCKeys.enabled] = enabled }
        if let bpm { message[WCKeys.bpm] = bpm }

        s.sendMessage(message, replyHandler: nil) { error in
            if self.debugEnabled {
                print(" Watch send error:", error.localizedDescription)
            }
        }
    }

    private func requestHeartRateAuthorizationIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        healthStore.requestAuthorization(toShare: [], read: [hrType]) { success, error in
            if self.debugEnabled {
                if let error { print(" HealthKit auth error:", error.localizedDescription) }
                print("HealthKit auth success:", success)
            }
        }
    }

    private func startHeartRateUpdates() {
        stopHeartRateUpdates()

        hrTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.fetchAndSendCurrentHeartRate()
        }
        RunLoop.main.add(hrTimer!, forMode: .common)
    }

    private func stopHeartRateUpdates() {
        hrTimer?.invalidate()
        hrTimer = nil
        lastSentBpm = nil
    }

    private func fetchAndSendCurrentHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let query = HKSampleQuery(
            sampleType: type,
            predicate: nil,
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
        ) { [weak self] _, samples, error in
            guard let self else { return }
            if let error, self.debugEnabled {
                print("HR query error:", error.localizedDescription)
            }

            guard let sample = samples?.first as? HKQuantitySample else { return }

            let unit = HKUnit.count().unitDivided(by: .minute())
            let bpm = Int(sample.quantity.doubleValue(for: unit))

            let now = Date()
            if now.timeIntervalSince(self.lastBpmSentAt) < 1.0 { return }
            if self.lastSentBpm == bpm { return }

            self.lastSentBpm = bpm
            self.lastBpmSentAt = now

            self.send(action: WCKeys.heartRateUpdate, bpm: bpm)
        }

        healthStore.execute(query)
    }

    private func debugWCSession() {
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
        if let error, debugEnabled {
            print(" WC Watch activation error:", error.localizedDescription)
        }
        if debugEnabled {
            print("WC activated:", activationState.rawValue)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let dto = WCMessageCodec.decodeModeDTO(from: message) {
                self.currentMode = dto
            }
        }
    }
}
