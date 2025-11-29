import HomeKit
import Combine

final class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryBrowserDelegate {
    static let shared = HomeKitManager()  // Singleton
    
    var homeManager: HMHomeManager!
    var browser = HMAccessoryBrowser()
    @Published var foundAccessories: [HMAccessory] = []
    
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
        
        // FONCTION CORRIGÉE : Afficher les accessoires d'une maison spécifique
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
        
        // NOUVELLE FONCTION : Contrôler un accessoire
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
    }
