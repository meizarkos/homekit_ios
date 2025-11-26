//
//  Acceloro_Gyro.swift
//  WatchAppStoryboard
//
//  Created by Valentin on 25/11/2025.
//

import CoreMotion
import SwiftUI

class MotionAnalysis {
    let motionManager = CMMotionManager()
    
    init(){
        motionManager.accelerometerUpdateInterval = 1.0   // sample time
        motionManager.gyroUpdateInterval = 1.0
    }
    
    func startAllSensor(){
        motionManager.startAccelerometerUpdates()
        motionManager.startGyroUpdates()
    }
    
    func stopAllSensor(){
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
    }
    
    func getMotionData(sound : Binding<Int>){
        var accelaration : Double = 0
        var gyroSpeed : Double = 0
        guard motionManager.isAccelerometerAvailable else {
            //print("Accelerometer not available (likely simulator).")
            return
        }
        if let acc = motionManager.accelerometerData {
            let ax = acc.acceleration.x
            let ay = acc.acceleration.y
            let az = acc.acceleration.z
            //print("Accelerometer x: \(ax), y: \(ay), z: \(az)")
            accelaration = sqrt(ax*ax) + sqrt(ay*ay) + sqrt(az*az)
        }
        
        guard motionManager.isGyroAvailable else {
            print("Gyro can't be access geez")
            return
        }
        if let gyro = motionManager.gyroData {
            let gx = gyro.rotationRate.x
            let gy = gyro.rotationRate.y
            let gz = gyro.rotationRate.z
            //print("Gyroscope x: \(gx), y: \(gy), z: \(gz)")
            gyroSpeed = sqrt((gx*gx)) + sqrt((gy*gy)) + sqrt((gz*gz))
        }
        
        sound.wrappedValue = Int(accelaration + gyroSpeed)*3
    }
}
