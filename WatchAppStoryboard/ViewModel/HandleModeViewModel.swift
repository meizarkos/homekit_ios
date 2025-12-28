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
       @Published var isAutoModeOn : Bool = false
       @Published var selectedColor: LightColor? = nil
       @Published var selectedTemp: HMAccessory? = nil
       @Published var selectedLightAccessory: HMAccessory? = nil
       @Published var selectedSoundAccessory: HMAccessory? = nil
       @Published var hue: Double = 0
       

    //  Ampoules sélectionnées pour CE mode
    @Published var selectedLightAccessoryIds: Set<UUID> = []

    var homeKitManager: HomeKitManager = HomeKitManager.shared

    var timerForAutoMode: Timer? = nil
    let camera = PictureAnalysis()
    var motionSensor = MotionAnalysis()
    
    private let homeName: String

    init(name: String, temperature: Int, sound: Int, luminosity: Int, homeName: String) {
        self.name = name
        self.temperature = temperature
        self.sound = sound
        self.luminosity = luminosity
        self.power = 0
        self.homeName = homeName


        DispatchQueue.main.async {
            self.autoSelectAccessories()

            
            self.callTempHomekit()
            self.callSoundHomekit()
            self.callLuminosityHomekit()

            self.camera.onPhotoCaptured = { [weak self] image in
                self?.handleNewImage(image: image)
            }
        }
    }
    
    // Fonction pour sélectionner automatiquement les accessoires

    private func autoSelectAccessories() {
           guard let home = homeKitManager.homeManager.homes.first(where: { $0.name == homeName }) else {
               print("Home '\(homeName)' not found")
               return
           }
           
           // Sélectionner le premier accessoire de type lumière si disponible
           if selectedLightAccessory == nil {
               selectedLightAccessory = home.accessories.first
               if let accessory = selectedLightAccessory {
                   print("Auto-selected light accessory: \(accessory.name)")
               }
           }
           
           // Sélectionner le premier accessoire de type son si disponible
           if selectedSoundAccessory == nil {
               // On peut utiliser le même ou un différent
               selectedSoundAccessory = home.accessories.first
               if let accessory = selectedSoundAccessory {
                   print("Auto-selected sound accessory: \(accessory.name)")
               }
           }
       }

    func handleNewImage(image: UIImage?) {
        let cameraLux = camera.analyzeLuminosity(from: image)
        if cameraLux == -1 { return }

            luminosity = cameraLux
            callLuminosityHomekit()
        
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
            print("Luminosity: \(luminosity)%")

            guard let accessory = selectedLightAccessory else {
                print(" No selected light accessory")
                return
            }

            print(" Applying to: \(accessory.name)")
            //homeKitManager.setLightPower(accessory, isOn: luminosity > 0)
            homeKitManager.setLightBrightness(accessory, brightness: luminosity)
        }
    
    func updateColor() {
            guard
                let accessory = selectedLightAccessory
            else { return }
            homeKitManager.setLightColor(accessory, hue: self.hue)
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
