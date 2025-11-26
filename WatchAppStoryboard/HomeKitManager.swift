import HomeKit
import Combine

final class HomeKitManager: NSObject, ObservableObject, HMHomeManagerDelegate, HMAccessoryBrowserDelegate {
    static let instance = HomeKitManager()
    
    var homeManager: HMHomeManager!
    var browser = HMAccessoryBrowser()
    @Published var foundAccessories: [HMAccessory] = []
    
    private override init() {
        super.init()
        let manager = HMHomeManager()
        manager.delegate = self
        self.homeManager = manager
        self.browser.delegate = self
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
        
        DispatchQueue.main.async{ [weak self] in
            guard let self = self else { return }
            self.foundAccessories.append(accessory)
            print("Accessoire trouvé : \(accessory.name)")
        }
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
                return
            }

            guard let home = home else { return }

            /**if self.homeManager.primaryHome == nil {
                self.homeManager.updatePrimaryHome(home) { error in
                    if let error {
                        print("Failed to set primary home: \(error.localizedDescription)")
                    } else {
                        print("Primary home set: \(home.name)")
                    }
                }
            }
            
            DispatchQueue.main.async {
                home.addRoom(withName: "Test") { room, error in
                    if let error {
                        print("Failed to add room: \(error.localizedDescription)")
                    } else {
                        print("Successfully added room: \(room?.name ?? "nil")")
                    }
                }
            }**/

            print("Successfully added home: \(home.name)")
        }
    }


    
    func addAccessoryToHome(_ accessory: HMAccessory) {
        guard let home = homeManager.primaryHome else {
            print("No home available")
            return
        }
        print("Requesting to add accessory: \(accessory.name) to \(home.name)")
        
        /**home.assignAccessory(accessory,to: home.roomForEntireHome()){error in
            if let error {
                print("Failed to add accessory: \(error.localizedDescription)")
            }
            else{
                print("Succesfull add to room")
            }
            print("\(accessory.services)")
        }**/
            
        home.addAccessory(accessory) { error in
            if let error {
                print("Failed to add accessory: \(error.localizedDescription)")
            } else {
                print("Accessory added: \(accessory.name)")
            }
        }
    }
    
    func addAccessoryUsingUrl(name: String, url: URL) {
        let request = HMAccessorySetupRequest()
        request.suggestedAccessoryName = name
        let home = homeManager.primaryHome!
        request.homeUniqueIdentifier = home.uniqueIdentifier
        let room = home.roomForEntireHome()
        request.suggestedRoomUniqueIdentifier = room.uniqueIdentifier
        request.payload = HMAccessorySetupPayload(url: url)

        let setupManager = HMAccessorySetupManager()
        setupManager.performAccessorySetup(using: request, completionHandler: { result, error in
            if let error = error {
                print("Error while adding accessory named \(name) to home \(home.name), room \(room.name): \(error.localizedDescription)")
            }
            else {
                print("Accesory should be added lol")
            }
        })
    }
}


