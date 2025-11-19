import HomeKit
import Combine

class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryBrowserDelegate {
    var homeManager: HMHomeManager!
    let browser = HMAccessoryBrowser()
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
                home.rooms.forEach{ room in
                    print("\(room.name)")
                }
            }
            print("Vous avez \(manager.homes.count) maison")
        }
        else{
            print("No home")
        }
    }
    
    func startScanning() {
        if(foundAccessories.count > 0){
            turnAllLight(on: true)
        }
        foundAccessories.removeAll()
        print("Start scanning")
        browser.startSearchingForNewAccessories()
    }
        
    func stopScanning() {
        print("Stop scanning")
        browser.stopSearchingForNewAccessories()
    }
    
    func accessoryBrowser(_ browser: HMAccessoryBrowser,
                          didFindNewAccessory accessory: HMAccessory) {
        DispatchQueue.main.async {
            self.foundAccessories.append(accessory)
        }
        print("Accessoire trouvé : \(accessory.name)")
    }
        
    func accessoryBrowser(_ browser: HMAccessoryBrowser,
                          didRemoveNewAccessory accessory: HMAccessory) {
        DispatchQueue.main.async {
            self.foundAccessories.removeAll { $0.uniqueIdentifier == accessory.uniqueIdentifier }
        }
        print("Accessoire retiré : \(accessory.name)")
    }
    
    func addHome(named name: String) {
        homeManager.addHome(withName: name) { home, error in
            if let error {
                print("Failed to add home: \(error.localizedDescription)")
            } else if let home {
                home.addRoom(withName: "Test"){ room, eror in
                    if let error {
                        print("Failed to add room: \(error.localizedDescription)")
                    }
                    else {
                        print("Succesfully added room")
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
        print("Requesting to add accessory: \(accessory.name)")
            
        home.addAccessory(accessory) { error in
            if let error {
                print("Failed to add accessory: \(error.localizedDescription)")
            } else {
                print("Accessory added: \(accessory.name)")
            }
        }
    }
}


