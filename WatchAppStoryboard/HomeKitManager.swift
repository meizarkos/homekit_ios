import HomeKit
import Combine

final class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryBrowserDelegate {
    static let shared = HomeKitManager()  // Singleton

    var homeManager: HMHomeManager!
    var browser = HMAccessoryBrowser()

    @Published var foundAccessories: [HMAccessory] = []

    @Published var selectedLightAccessory: HMAccessory? = nil

    override init() {
        super.init()
        let manager = HMHomeManager()
        manager.delegate = self
        self.homeManager = manager
        self.browser.delegate = self
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

    // Afficher les accessoires d'une maison spécifique
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
        print(" Start scanning for new accessories...")
        browser.startSearchingForNewAccessories()
    }

    func stopScanning() {
        print(" Stop scanning")
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
                home.addRoom(withName: "Test") { _, error in
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

    // (Propre) Retourne la maison courante
    func currentHome() -> HMHome? {
        homeManager.primaryHome ?? homeManager.homes.first
    }

    // (Propre) Retourne TOUTES les ampoules (accessoires avec service Lightbulb) de la maison
    func getAllLightsFromHome() -> [HMAccessory] {
        guard let home = currentHome() else { return [] }
        return home.accessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLightbulb }
        }
    }

    // (NÉCESSAIRE) Retourne les accessoires correspondant à une liste de UUID
    // → utilisé par HandleModeViewModel pour appliquer un mode à plusieurs ampoules
    func getAccessoriesByIds(_ ids: [UUID]) -> [HMAccessory] {
        guard let home = currentHome() else { return [] }
        return home.accessories.filter { ids.contains($0.uniqueIdentifier) }
    }

    // Contrôler un accessoire (PowerState)
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

    // Allumer / éteindre une ampoule
    func setLightPower(_ accessory: HMAccessory, isOn: Bool) {
        for service in accessory.services {
            for characteristic in service.characteristics {
                if characteristic.characteristicType == HMCharacteristicTypePowerState {
                    characteristic.writeValue(isOn) { error in
                        if let error = error {
                            print(" Failed to set power: \(error.localizedDescription)")
                        } else {
                            print(" Light power set to \(isOn ? "ON" : "OFF") (\(accessory.name))")
                        }
                    }
                }
            }
        }
    }

    // Régler la luminosité (0..100)
    func setLightBrightness(_ accessory: HMAccessory, brightness: Int) {
        let value = max(0, min(brightness, 100))

        for service in accessory.services {
            for characteristic in service.characteristics {
                if characteristic.characteristicType == HMCharacteristicTypeBrightness {
                    characteristic.writeValue(value) { error in
                        if let error = error {
                            print(" Failed to set brightness: \(error.localizedDescription)")
                        } else {
                            print(" Brightness set to \(value) (\(accessory.name))")
                        }
                    }
                }
            }
        }
    }
}
