import Foundation
import Combine

class ModeViewModel: ObservableObject {
    @Published var modes: [Mode] = [] {
        didSet {
            ModeStorage.shared.save(modes)
        }
    }
    
    @Published var currentMode: Mode? {
        didSet {
            if let mode = currentMode {
                UserDefaults.standard.set(mode.id.uuidString, forKey: "currentModeId")
                applyMode(mode)
            } else {
                UserDefaults.standard.removeObject(forKey: "currentModeId")
            }
        }
    }
    
    private let homeKitManager = HomeKitManager.shared
    
    init() {
        modes = ModeStorage.shared.load()
        loadCurrentMode()
    }
    
    private func loadCurrentMode() {
        if let currentModeId = UserDefaults.standard.string(forKey: "currentModeId"),
           let uuid = UUID(uuidString: currentModeId) {
            currentMode = modes.first(where: { $0.id == uuid })
        }
    }
    
    func addModes(_ mode: Mode) {
        modes.append(mode)
    }
    
    func deleteMode(at indexSet: IndexSet) {
        let modeToDelete = indexSet.map { modes[$0] }
        
        if let deletedMode = modeToDelete.first, deletedMode.id == currentMode?.id {
            currentMode = nil
        }
        
        modes.remove(atOffsets: indexSet)
    }
    
    func updateModes(_ mode: Mode) {
        guard let index = modes.firstIndex(where: { $0.id == mode.id }) else { return }
        modes[index] = mode
        
        if currentMode?.id == mode.id {
            currentMode = mode
        }
    }
    
    func selectMode(_ mode: Mode) {
        currentMode = mode
    }
    
    func deselectMode() {
        currentMode = nil
    }
    
    private func applyMode(_ mode: Mode) {
        print("Application du mode: \(mode.name)")
        
        if let activeVM = ActiveHandleModeHolder.shared.current {
            activeVM.luminosity = mode.luminosity
            activeVM.sound = mode.sound
            activeVM.temperature = mode.temperature
            activeVM.hue = mode.hue  // SI ton Mode a un champ hue
            
            activeVM.callLuminosityHomekit()
            activeVM.callSoundHomekit()
            activeVM.callTempHomekit()
            activeVM.updateColor()
        } else {
            // Appliquer directement via HomeKit
            let lights = homeKitManager.getAllLightsFromHome()
            
            for light in lights {
                // 1. LUMINOSITE
                homeKitManager.setLightBrightness(light, brightness: mode.luminosity)
                
                // 2. COULEUR
                homeKitManager.setLightColor(light, hue: mode.hue) // SI ton Mode a un champ hue
                
                // 3. TEMPERATURE
                homeKitManager.setAccessoryTemperature(light, temperature: mode.temperature)
                
                // 4. SON
                homeKitManager.setSpeakerVolume(light, volume: mode.sound)
            }
            
            print("Mode appliqué à \(lights.count) lumière(s)")
        }
    }
}
