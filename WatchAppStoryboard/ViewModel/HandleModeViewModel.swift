
import Foundation
import SwiftUI
import Combine
import AVFoundation
import SensorKit
import HomeKit

enum LightColor: String {
    case yellow
    case blue
    case red
}

class HandleModeViewModel: ObservableObject {
    @Published var power: Int
    @Published var id: UUID = UUID()
    @Published var name: String
    @Published var temperature: Int
    @Published var sound: Int
    @Published var luminosity: Int
    @Published var isAutoModeOn: Bool = false
    @Published var selectedColor: LightColor? = nil

    //  Ampoules sélectionnées pour CE mode
    @Published var selectedLightAccessoryIds: Set<UUID> = []

    var homeKitManager: HomeKitManager = HomeKitManager.shared

    var timerForAutoMode: Timer? = nil
    let camera = PictureAnalysis()
    var motionSensor = MotionAnalysis()

    init(name: String, temperature: Int, sound: Int, luminosity: Int) {
        self.name = name
        self.temperature = temperature
        self.sound = sound
        self.luminosity = luminosity
        self.power = 0

        DispatchQueue.main.async {
            self.callTempHomekit()
            self.callSoundHomekit()
            self.callLuminosityHomekit()

            self.camera.onPhotoCaptured = { [weak self] image in
                self?.handleNewImage(image: image)
            }
        }
    }

    func handleNewImage(image: UIImage?) {
        let cameraLux = camera.analyzeLuminosity(from: image)
        if cameraLux == -1 { return }

        DispatchQueue.main.async {
            self.luminosity = cameraLux
            self.callLuminosityHomekit()
        }
    }

    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }

        case .denied, .restricted:
            completion(false)

        @unknown default:
            completion(false)
        }
    }

    func startAutoMode() {
        isAutoModeOn = true

        DispatchQueue.global().async {
            self.camera.startSession()
            self.motionSensor.startAllSensor()
        }

        print("Auto-Mode has all access up and running")

        timerForAutoMode = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self else { return }

            self.camera.capture()
            self.motionSensor.getMotionData(sound: Binding<Int>(
                get: { self.sound },
                set: { self.sound = $0 }
            ))
            self.callSoundHomekit()
        }
    }

    func stopAutoMode() {
        isAutoModeOn = false

        DispatchQueue.global().async {
            self.camera.stopSession()
            self.motionSensor.stopAllSensor()
        }

        print("Auto mode stopped")
        timerForAutoMode?.invalidate()
        timerForAutoMode = nil
    }

    func toMode() -> Mode {
        Mode(
            id: id,
            name: name,
            temperature: temperature,
            sound: sound,
            luminosity: luminosity,
            lightAccessoryIds: Array(selectedLightAccessoryIds)
        )
    }

    //  Appliquer la luminosité à TOUTES les ampoules du mode
    func callLuminosityHomekit() {
        let value = max(0, min(luminosity, 100))
        print("Lum is : \(value)")

        let accessories = homeKitManager.getAccessoriesByIds(Array(selectedLightAccessoryIds))
        guard !accessories.isEmpty else {
            print(" No selected lights for this mode")
            return
        }

        for accessory in accessories {
            homeKitManager.setLightPower(accessory, isOn: value > 0)
            homeKitManager.setLightBrightness(accessory, brightness: value)
        }
    }

    func callSoundHomekit() {
        print("Sound is : \(sound)")
    }

    func callTempHomekit() {
        print("Temp is : \(temperature)")
    }

    func updateColor(color: LightColor?) {
        guard let color else {
            print("Color is nil")
            return
        }
        print("Color is \(color.rawValue)")
    }
}
