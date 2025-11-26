//
//  PcitureAnalysis.swift
//  WatchAppStoryboard
//
//  Created by Valentin on 24/11/2025.
//

import AVFoundation
import UIKit

class PictureAnalysis: NSObject, AVCapturePhotoCaptureDelegate {
    
    private let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    
    var onPhotoCaptured: ((UIImage?) -> Void)?
    
    override init() {
        super.init()
        setup()
    }
    
    private func setup() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, //get input ( back camera )
                                                   for: .video,
                                                   position: .back),
            let input = try? AVCaptureDeviceInput(device: device), // add as an input
            session.canAddInput(input)   // AVCCaptureSession allowed to add this to session
        else {
            print("No camera")
            return
        }
        session.addInput(input)
        guard session.canAddOutput(photoOutput) else { return } // Get an output to read camera sortie
        session.addOutput(photoOutput)
        session.commitConfiguration()
    }
    
    func startSession() {
            /**#if targetEnvironment(simulator)
            print("Simulator – skipping camera session")
            #else**/
            if !session.isRunning {
                session.startRunning()
            }
            //#endif
        }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func capture() {
            /**#if targetEnvironment(simulator)
            let size = CGSize(width: 100, height: 100)
            UIGraphicsBeginImageContext(size)
            UIColor.white.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
            let fakeImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            onPhotoCaptured?(fakeImage)
            #else**/
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self) //Take picture + send event to delegate
            //#endif
        }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        guard let data = photo.fileDataRepresentation(), // Transform photo to .jpeg
              let image = UIImage(data: data) // Transform to UIImage
        else {
            onPhotoCaptured?(nil)
            return
        }
        onPhotoCaptured?(image)
    }
    
    func analyzeLuminosity(from image: UIImage?) -> Int{
        guard let image = image else {
            print("No image")
            return -1
        }
        guard let cgImage = image.cgImage else {
            print("Conversion didnt work")
            return -1
        }
        
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent // = use the whole image
        let avg = CIFilter(name: "CIAreaAverage", // Will output 1 by 1 pixel
                           parameters: [kCIInputImageKey: ciImage,
                                        kCIInputExtentKey: CIVector(cgRect: extent)])! // must be vector ( conversion ) and is use to tell whiich part of image to analyse ( here all of the image )
        
        let output = avg.outputImage! // pixel de couleur = 4 bytes
        var bitmap = [UInt8](repeating: 0, count: 4) // 4 bit coming from one pixel

        let context = CIContext()
        context.render(output, // = Change the output (define as RECT ) to RGBA8 sorted format
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: nil)

        let r = Float(bitmap[0]) / 255.0
        let g = Float(bitmap[1]) / 255.0
        let b = Float(bitmap[2]) / 255.0

        let brightness = 100 - ((r + g + b) / 3.0) * 100
        return Int(brightness)
    }
}
