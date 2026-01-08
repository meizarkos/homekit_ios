import HomeKit
import Combine

final class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryBrowserDelegate {
    static let shared = HomeKitManager()  // Singleton
    
    var homeManager: HMHomeManager!
    var browser = HMAccessoryBrowser()
    @Published var foundAccessories: [HMAccessory] = []
    @Published var assignedAccessories: [HMAccessory] = []
    @Published var homes: [HMHome] = []
    
    override init() {
        super.init()
        let manager = HMHomeManager()
        manager.delegate = self
        self.homeManager = manager
        self.browser.delegate = self
    }
    
    func refreshAll() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.homes = self.homeManager.homes
            self.refreshAssignedAccessories()
            print("Full refresh completed")
        }
    }
    
    func refreshAssignedAccessories() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            var allAccessories: [HMAccessory] = []
            
            for home in self.homeManager.homes {
                allAccessories.append(contentsOf: home.accessories)
            }
            
            self.assignedAccessories = allAccessories
            print("Assigned accessories refreshed: \(allAccessories.count)")
        }
    }
    
    public func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        if manager.homes.count > 0 {
            manager.homes.forEach { home in
                home.rooms.forEach { room in
                    print("\(room.name)")
                }
            }
            print("Vous avez \(manager.homes.count) maison(s)")
        } else {
            print("No home")
        }
    }
    
    
    func printAccessoriesFromHome(_ home: HMHome) {
        print("\n=== Accessoires de \(home.name) ===")
        print("Nombre total: \(home.accessories.count)")
        
        if home.accessories.isEmpty {
            print("Aucun accessoire dans cette maison")
        } else {
            home.accessories.forEach { accessory in
                print("\nAccessoire: \(accessory.name)")
                print("   - ID: \(accessory.uniqueIdentifier)")
                print("   - Type: \(accessory.category.categoryType)")
                print("   - Pièce: \(accessory.room?.name ?? "Aucune")")
                print("   - Disponible: \(accessory.isReachable ? "Oui" : "Non")")
                
                // Afficher les services
                print("   - Services (\(accessory.services.count)):")
                accessory.services.forEach { service in
                    print("      - \(service.name) (\(service.serviceType))")
                }
            }
        }
        print("=== Fin de la liste ===\n")
    }
    
    func startScanning() {
        foundAccessories.removeAll()
        print("🔍 Start scanning for new accessories...")
        browser.startSearchingForNewAccessories()
    }
    
    func stopScanning() {
        print("🛑 Stop scanning")
        browser.stopSearchingForNewAccessories()
    }
    
    func accessoryBrowser(_ browser: HMAccessoryBrowser,
                          didFindNewAccessory accessory: HMAccessory) {
        DispatchQueue.main.async {
            self.foundAccessories.append(accessory)
        }
        print("Nouvel accessoire trouvé : \(accessory.name)")
    }
    
    func accessoryBrowser(_ browser: HMAccessoryBrowser,
                          didRemoveNewAccessory accessory: HMAccessory) {
        DispatchQueue.main.async {
            self.foundAccessories.removeAll { $0.uniqueIdentifier == accessory.uniqueIdentifier }
        }
        print(" Accessoire retiré : \(accessory.name)")
    }
    
    func addHome(named name: String) {
        homeManager.addHome(withName: name) { home, error in
            if let error {
                print(" Failed to add home: \(error.localizedDescription)")
            } else if let home {
                home.addRoom(withName: "Test") { room, error in
                    if let error {
                        print("Failed to add room: \(error.localizedDescription)")
                    } else {
                        print(" Successfully added room")
                    }
                }
                print("Successfully added home: \(home.name)")
            }
        }
    }
    
    func removeHome(_ home: HMHome) {
        homeManager.removeHome(home) { [weak self] error in
            if let error {
                print("Failed to remove home: \(error.localizedDescription)")
            } else {
                print("Successfully removed home: \(home.name)")
                self?.refreshAll()
            }
        }
    }
    
    func addAccessoryToHome(_ accessory: HMAccessory) {
        guard let home = homeManager.primaryHome ?? homeManager.homes.first else {
            print("No home available")
            return
        }
        print("⏳ Requesting to add accessory: \(accessory.name)")
        
        home.addAccessory(accessory) { error in
            if let error {
                print("Failed to add accessory: \(error.localizedDescription)")
            } else {
                print(" Accessory added: \(accessory.name)")
            }
        }
    }
    
    func removeAccessory(_ accessory: HMAccessory, from home: HMHome) {
        home.removeAccessory(accessory) { [weak self] error in
            if let error {
                print("Failed to remove accessory: \(error.localizedDescription)")
            } else {
                print("Successfully removed accessory: \(accessory.name)")
                self?.refreshAll()
            }
        }
    }
    
    
    func controlAccessory(_ accessory: HMAccessory, turnOn: Bool) {
        accessory.services.forEach { service in
            service.characteristics.forEach { characteristic in
                if characteristic.characteristicType == HMCharacteristicTypePowerState {
                    characteristic.writeValue(turnOn) { error in
                        if let error {
                            print("Erreur contrôle : \(error.localizedDescription)")
                        } else {
                            print(" \(accessory.name) : \(turnOn ? "ON" : "OFF")")
                        }
                    }
                }
            }
        }
    }
    
    
    func setLightBrightness(_ accessory: HMAccessory, brightness: Int) {
        let value = max(0, min(brightness, 100)) // Clamp entre 0 et 100
        
        for service in accessory.services {
            for characteristic in service.characteristics {
                
                if characteristic.characteristicType == HMCharacteristicTypeBrightness {
                    characteristic.writeValue(value) { error in
                        if let error = error {
                            print(" Failed to set brightness: \(error.localizedDescription)")
                        } else {
                            print(" Brightness set to \(value)")
                        }
                    }
                }
            }
        }
    }
    func setLightColor(
        _ accessory: HMAccessory,
        hue: Double
    ) {
        for service in accessory.services {
            guard service.serviceType == HMServiceTypeLightbulb else { continue }
            
            for characteristic in service.characteristics {
                switch characteristic.characteristicType {
                    
                case HMCharacteristicTypeHue:
                    characteristic.writeValue(hue){
                        error in
                        if let error = error {
                            print(" Failed to set hue: \(error.localizedDescription)")
                        } else {
                            print(" Hue set to \(hue)")
                        }
                    }
                default:
                    break
                }
            }
        }
    }
    func setSpeakerVolume(_ accessory: HMAccessory, volume: Int) {
        let value = max(0, min(volume, 100))
        
        for service in accessory.services {
            guard service.serviceType == HMServiceTypeSpeaker else { continue }
            
            for characteristic in service.characteristics {
                if characteristic.characteristicType == HMCharacteristicTypeVolume {
                    characteristic.writeValue(Float(value)) { error in
                        if let error {
                            print("Failed to set volume: \(error.localizedDescription)")
                        } else {
                            print("Volume set to \(value)")
                        }
                    }
                }
            }
        }
    }
    
    func setTargetTemperature(_ accessory: HMAccessory, temperature: Int) {
        for service in accessory.services {
            guard service.serviceType == HMServiceTypeThermostat else { continue }
            
            for characteristic in service.characteristics {
                if characteristic.characteristicType == HMCharacteristicTypeTargetTemperature {
                    characteristic.writeValue(Double(temperature)) { error in
                        if let error {
                            print("Failed to set temperature: \(error.localizedDescription)")
                        } else {
                            print("Temperature set to \(temperature)°C")
                        }
                    }
                }
            }
        }
    }

    func getAllLightsFromHome() -> [HMAccessory] {
        guard let home = currentHome() else { return [] }
        return home.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLightbulb }
        }
    }
    
    func currentHome() -> HMHome? {
        homeManager.primaryHome ?? homeManager.homes.first
    }
    
    func getAccessoriesByIds(_ ids: [UUID]) -> [HMAccessory] {
        guard let home = currentHome() else { return [] }
        return home.accessories.filter { ids.contains($0.uniqueIdentifier) }
    }
    
    func getAllThermostatsFromHome() -> [HMAccessory] {
        guard let home = currentHome() else { return [] }
        return home.accessories.filter { accessory in
            accessory.category.categoryType == HMAccessoryCategoryTypeThermostat
        }
    }

    func setAccessoryTemperature(_ accessory: HMAccessory, temperature: Int) {
        let value = max(10, min(temperature, 30))
        
        accessory.services.forEach { service in
            service.characteristics.forEach { characteristic in
                if characteristic.characteristicType == HMCharacteristicTypeTargetTemperature {
                    characteristic.writeValue(Double(value)) { error in
                        if let error {
                            print("Erreur température : \(error.localizedDescription)")
                        } else {
                            print("Température réglée à \(value)° pour \(accessory.name)")
                        }
                    }
                }
            }
        }
    }
}
