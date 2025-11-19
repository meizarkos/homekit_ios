import HomeKit
import Combine

extension HomeKitManager {
    func getAllLights() -> [HMAccessory] {
        foundAccessories.forEach { accesory in
            //print("\(accesory.category)")
            print("\(accesory.services)")
            //print("\(HMServiceTypeLightbulb)")
            /**accesory.services.forEach { service in
                print("\(service.serviceType)")
                
            }**/
        }
        return foundAccessories.filter { accessory in
            accessory.services.contains { $0.serviceType == HMServiceTypeLightbulb }
        }
    }
    
    func setLight(_ accessory: HMAccessory, power: Bool) {
        guard let lightService = accessory.services.first(where: {
            $0.serviceType == HMServiceTypeLightbulb
        }) else {
            print("Light service not found")
            return
        }
        
        guard let powerCharacteristic = lightService.characteristics.first(where: {
            $0.characteristicType == HMCharacteristicTypePowerState
        }) else {
            print("Power characteristic not found")
            return
        }
        
        powerCharacteristic.writeValue(power) { error in
            if let error = error {
                print("Failed to set light state: \(error.localizedDescription)")
            } else {
                print("Light turned \(power ? "ON" : "OFF")")
            }
        }
    }

    func turnAllLight(on: Bool) {
        let lights = getAllLights()
        
        lights.forEach { light in
            print(light.name)
            setLight(light, power: on)
        }
    }
}
