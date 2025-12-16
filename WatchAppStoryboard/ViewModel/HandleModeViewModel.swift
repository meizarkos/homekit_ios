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
    var homeKitManager: HomeKitManager = HomeKitManager.shared
    
    var timerForAutoMode : Timer? = nil
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

        // Sélection automatique du premier accessoire disponible
        DispatchQueue.main.async {
            self.autoSelectAccessories()
            
            // Appliquer les valeurs initiales
            self.callTempHomekit()
            self.callSoundHomekit()
            self.callLuminosityHomekit()

            self.camera.onPhotoCaptured = { image in
                self.handleNewImage(image: image)
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
    
    func handleNewImage(image : UIImage?) {
        let cameraLux = camera.analyzeLuminosity(from: image)
        if(cameraLux == -1){
            return
        }
        luminosity = cameraLux
        callLuminosityHomekit()
    }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }

        case .denied, .restricted:
            completion(false)

        @unknown default:
            completion(false)
        }
    }
    
    func startAutoMode(){
        isAutoModeOn = true
        DispatchQueue.global().async {
            self.camera.startSession()
            self.motionSensor.startAllSensor()
        }
        print("Auto-Mode has all access up and running")
        
        timerForAutoMode = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.camera.capture()
            self.motionSensor.getMotionData(sound : Binding<Int>(
                get: { self.sound },
                set: { self.sound = $0 }
            ))
            self.callSoundHomekit()
        }
    }
    
    func stopAutoMode(){
        isAutoModeOn = false
        DispatchQueue.global().async {
            self.camera.stopSession()
            self.motionSensor.stopAllSensor()
        }
        print("Auto mode stopped")
        timerForAutoMode?.invalidate()
        timerForAutoMode = nil
    }
    
    func toMode() ->Mode{
        return Mode(
            name: name,
            temperature: temperature,
            sound: sound,
            luminosity: luminosity
        )
    }
    
    func callLuminosityHomekit() {
        print("Luminosity: \(luminosity)%")

        guard let accessory = selectedLightAccessory else {
            print(" No selected light accessory")
            return
        }

        print(" Applying to: \(accessory.name)")
        homeKitManager.setLightPower(accessory, isOn: luminosity > 0)
        homeKitManager.setLightBrightness(accessory, brightness: luminosity)
    }
    
    func callSoundHomekit() {
        print(" Sound: \(sound)%")
        
        guard let accessory = selectedSoundAccessory else{
            print(" No selected sound accessory")
            return
        }
        
        print("Applying to: \(accessory.name)")
//        homeKitManager.setSoundVolume(accessory, volume: sound)
    }
    
    func callTempHomekit() {
        guard let accessory = selectedLightAccessory else {
            print("No selected temp accessory")
            return
        }

        print("Target temperature: \(temperature)°C")

        for service in accessory.services {
            if service.serviceType == HMServiceTypeThermostat {

                for characteristic in service.characteristics {
                    // Définir la température cible
                    if characteristic.characteristicType == HMCharacteristicTypeTargetTemperature {
                        characteristic.writeValue(Double(temperature)) { error in
                            if let error = error {
                                print("Error writing target temperature: \(error)")
                            } else {
                                print("Target temperature updated")
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateColor(color : LightColor?) {
        guard let color = color else {
            print("Color is nil")
            return
        }

        print(" Color selected: \(color.rawValue)")
        
        // TODO: Implémenter le changement de couleur si vos lumières supportent les couleurs
        guard let accessory = selectedLightAccessory else {
            print("⚠️ No light accessory selected")
            return
        }
        
        // Logique pour changer la couleur de la lumière
        // Cela dépend des caractéristiques disponibles (Hue, Saturation, etc.)
        
    }
}
