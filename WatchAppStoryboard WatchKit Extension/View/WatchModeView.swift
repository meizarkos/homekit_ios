//
//  WatchModeView.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import SwiftUI
import WatchKit

struct WatchModeView: View {
    @StateObject private var wc = WatchSessionManager_Watch.shared

    @State private var lum: Double = 0
    @State private var snd: Double = 0
    @State private var tmp: Double = 20
    @State private var autoEnabled: Bool = false
    @State private var hrModeEnabled = false


    var body: some View {
        ScrollView {
            VStack(spacing: 10) {

                // --- Luminosité (card + boutons + slider fin)
                ControlCard(
                    title: "Luminosité",
                    icon: "sun.max.fill",
                    tint: .yellow,
                    valueText: "\(Int(lum))",
                    onMinus: { setLum(Int(lum) - 1) },
                    onPlus:  { setLum(Int(lum) + 1) }
                ) {
                    Slider(value: $lum, in: 0...100, step: 1)
                        .onChange(of: lum) { _, newValue in
                            wc.send(action: WCKeys.setLuminosity, value: Int(newValue))
                        }
                }

                // --- Son
                ControlCard(
                    title: "Son",
                    icon: "speaker.wave.2.fill",
                    tint: .blue,
                    valueText: "\(Int(snd))",
                    onMinus: { setSound(Int(snd) - 1) },
                    onPlus:  { setSound(Int(snd) + 1) }
                ) {
                    Slider(value: $snd, in: 0...100, step: 1)
                        .onChange(of: snd) { _, newValue in
                            wc.send(action: WCKeys.setSound, value: Int(newValue))
                        }
                }

                // --- Température
                ControlCard(
                    title: "Température",
                    icon: "thermometer",
                    tint: .orange,
                    valueText: "\(Int(tmp))°",
                    onMinus: { setTemp(Int(tmp) - 1) },
                    onPlus:  { setTemp(Int(tmp) + 1) }
                ) {
                    Slider(value: $tmp, in: 10...30, step: 1)
                        .onChange(of: tmp) { _, newValue in
                            wc.send(action: WCKeys.setTemperature, value: Int(newValue))
                        }
                }

                // --- Auto (card propre)
                VStack(spacing: 8) {
                    Toggle(isOn: $autoEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .foregroundStyle(.blue)
                            Text("Auto")
                                .font(.headline)
                        }
                    }
                    .onChange(of: autoEnabled) { _, newValue in
                        haptic()
                        wc.send(action: WCKeys.toggleAuto, enabled: newValue)
                    }
                    
                }
                
                // --- Heart Rate Mode (card propre)
                VStack(spacing: 8) {
                    Toggle(isOn: $hrModeEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                            Text("Fréquence cardiaque")
                                .font(.headline)
                        }
                    }
                    .onChange(of: hrModeEnabled) { _, newValue in
                        haptic()
                        wc.send(action: WCKeys.toggleHeartRateMode, enabled: newValue)
                    }

                    Text(hrModeEnabled ? "LED pilotée par la FC" : "Désactivé")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
              

                .padding(12)
                .background(.thinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.top, 2)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
        }
        .onAppear { syncFromCurrentMode() }
        .onChange(of: wc.currentMode) { _, _ in syncFromCurrentMode() }
    }

    // MARK: - Helpers (boutons +/-)
    private func setLum(_ value: Int) {
        let clamped = min(max(value, 0), 100)
        guard clamped != Int(lum) else { return }
        lum = Double(clamped)
        haptic()
        wc.send(action: WCKeys.setLuminosity, value: clamped)
    }

    private func setSound(_ value: Int) {
        let clamped = min(max(value, 0), 100)
        guard clamped != Int(snd) else { return }
        snd = Double(clamped)
        haptic()
        wc.send(action: WCKeys.setSound, value: clamped)
    }

    private func setTemp(_ value: Int) {
        let clamped = min(max(value, 10), 30)
        guard clamped != Int(tmp) else { return }
        tmp = Double(clamped)
        haptic()
        wc.send(action: WCKeys.setTemperature, value: clamped)
    }

    private func haptic() {
        WKInterfaceDevice.current().play(.click)
    }

    private func syncFromCurrentMode() {
        guard let m = wc.currentMode else { return }
        lum = Double(m.luminosity)
        snd = Double(m.sound)
        tmp = Double(m.temperature)
    }
}

// MARK: - UI Components

struct ControlCard<Content: View>: View {
    let title: String
    let icon: String
    let tint: Color
    let valueText: String
    let onMinus: () -> Void
    let onPlus: () -> Void
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 8) {

            HStack {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundStyle(tint)
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(valueText)
                    .font(.headline)
                    .monospacedDigit()
            }

            HStack(spacing: 10) {
                StepButton(symbol: "minus", tint: tint, action: onMinus)
                StepButton(symbol: "plus", tint: tint, action: onPlus)
            }

            content
        }
        .padding(12)
        .background(tint.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct StepButton: View {
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 36)
        }
        .buttonStyle(.plain)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
    }
}
