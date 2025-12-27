//
//  WatchModeView.swift
//  WatchAppStoryboard
//
//  Created by Rishi Balasubramanim on 27/12/2025.
//

import SwiftUI

struct WatchModeView: View {
    @StateObject private var wc = WatchSessionManager_Watch.shared

    @State private var lum: Double = 0
    @State private var snd: Double = 0
    @State private var tmp: Double = 20
    @State private var autoEnabled: Bool = false

    var body: some View {
        VStack(spacing: 10) {

            Text(wc.currentMode?.name ?? "Aucun mode")
                .font(.headline)
                .lineLimit(1)

            VStack(alignment: .leading, spacing: 4) {
                Text("Lum \(Int(lum))").font(.caption2)
                Slider(value: $lum, in: 0...100, step: 1)
                    .onChange(of: lum) { _, newValue in
                        wc.send(action: WCKeys.setLuminosity, value: Int(newValue))
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Son \(Int(snd))").font(.caption2)
                Slider(value: $snd, in: 0...100, step: 1)
                    .onChange(of: snd) { _, newValue in
                        wc.send(action: WCKeys.setSound, value: Int(newValue))
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Temp \(Int(tmp))°").font(.caption2)
                Slider(value: $tmp, in: 10...30, step: 1)
                    .onChange(of: tmp) { _, newValue in
                        wc.send(action: WCKeys.setTemperature, value: Int(newValue))
                    }
            }

            Toggle("Auto", isOn: $autoEnabled)
                .onChange(of: autoEnabled) { _, newValue in
                    wc.send(action: WCKeys.toggleAuto, enabled: newValue)
                }
        }
        .padding()
        .onAppear { syncFromCurrentMode() }
        .onChange(of: wc.currentMode) { _, _ in syncFromCurrentMode() }
    }

    private func syncFromCurrentMode() {
        guard let m = wc.currentMode else { return }
        lum = Double(m.luminosity)
        snd = Double(m.sound)
        tmp = Double(m.temperature)
    }
}
