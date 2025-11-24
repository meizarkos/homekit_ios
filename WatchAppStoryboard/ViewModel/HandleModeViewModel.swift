import Foundation
import SwiftUI
import Combine
import AVFoundation
import SensorKit

enum LightColor: String {
    case yellow
    case blue
    case red
}

class HandleModeViewModel: ObservableObject {
    @Published var temp: Int
    @Published var sound: Int
    @Published var luminosity: Int
    @Published var isAutoModeOn : Bool = false
    @Published var selectedColor: LightColor? = nil
    
    var cameraLuminosity : Int? = nil
    var hasMoved : Bool? = nil
    var timerForAutoMode : Timer? = nil
    var camera = PictureAnalysis()
    
    init(temp: Int, sound: Int, luminosity: Int) {
        self.temp = temp
        self.sound = sound
        self.luminosity = luminosity
        self.callTempHomekit()
        self.callSoundHomekit()
        self.callLuminosityHomekit()
        camera.onPhotoCaptured = { image in
            self.handleNewImage(image : image)
        }
    }
    
    func handleNewImage(image : UIImage?) { // needed cause photoAnalyse is asynchronous
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
            completion(false)  // permission blocked

        @unknown default:
            completion(false)
        }
    }
    
    func startAutoMode(){
        isAutoModeOn = true
        
        DispatchQueue.main.async {
               self.camera.startSession()
        }
        
        print("Auto-Mode has all access up and running")
        timerForAutoMode = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.camera.capture()
        }
    }
    
    func stopAutoMode(){
        isAutoModeOn = false
        camera.stopSession()
        print("Auto mode stopped")
        timerForAutoMode?.invalidate()
        timerForAutoMode = nil
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
    
    func updateColor(color : LightColor?) {
        // can only be yellow blue red
        guard let color = color else {
            print("Color is nil")
            return
        }

        print("Color is \(color.rawValue)")
    }
    
    func updateAllAccesoriesFromMode(){
        
    }
}
