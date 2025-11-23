import Foundation
import Combine
import AVFoundation

class HandleModeViewModel: ObservableObject {
    @Published var temp: Int
    @Published var sound: Int
    @Published var luminosity: Int
    @Published var isAutoModeOn : Bool = false
    
    var cameraLuminosity : Int? = nil
    var hasMoved : Bool? = nil
    var timerForAutoMode : Timer? = nil
    
    init(temp: Int, sound: Int, luminosity: Int) {
        self.temp = temp
        self.sound = sound
        self.luminosity = luminosity
        self.callTempHomekit()
        self.callSoundHomekit()
        self.callLuminosityHomekit()
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
            completion(false)  // permission blocked

        @unknown default:
            completion(false)
        }
    }
    
    func startAutoMode(){
        isAutoModeOn = true
        temp = 50
        print("Auto-Mode has all access up and running")
    }
    
    func stopAutoMode(){
        isAutoModeOn = false
        print("Auto mode stopped")
    }
    
    func callLuminosityHomekit() {
        print("Lum is : \(luminosity)")
    }
    
    func callSoundHomekit() {
        print("Sound is : \(sound)")
    }
    
    func callTempHomekit() {
        print("Temp is : \(temp)")
    }
    
    func updateAllAccesoriesFromMode(){
        
    }
}
