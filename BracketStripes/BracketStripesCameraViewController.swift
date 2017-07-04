//
//  AAPLCameraViewController.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/07.
//
//
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Camera view controller
 */


import UIKit
import AVFoundation
import CoreMedia


// Completion handler prototypes
typealias Completion = (Bool)->Void
typealias CompletionWithError = (Bool, Error?)->Void
typealias CompletionWithImage = (UIImage?)->Void


@objc(BracketStripesCameraViewController)
class CameraViewController: UIViewController, ImageViewDelegate {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // Capture
    private var captureSession: AVCaptureSession?
    private var captureDevice: AVCaptureDevice?
    private var captureDeviceFormat: AVCaptureDeviceFormat?
    private var stillImageOutput: AVCaptureStillImageOutput?
    
    // Brackets
    private var maxBracketCount: Int = 0
    private var bracketSettings: [AVCaptureBracketedStillImageSettings]?
    
    // UI
    @IBOutlet private var _cameraPreviewView: CapturePreviewView!
    @IBOutlet private var _cameraShutterButton: UIButton!
    @IBOutlet private var _bracketModeControl: UISegmentedControl!
    
    // Striped rendered brackets
    private var imageStripes: StripedImage?
    
    
    // Convenience for enable/disable UI controls
    private var userInterfaceEnabled: Bool {
        set {
            _cameraShutterButton?.isEnabled = newValue
            _bracketModeControl?.isEnabled = newValue
        }
        
        
        get {
            return _cameraShutterButton.isEnabled
            
        }
    }
    
    
    private func cameraDeviceForPosition(_ position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        for device in AVCaptureDevice.devices() as! [AVCaptureDevice] {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    
    private func showErrorMessage(_ message: String, title: String) {
        let alert = UIAlertView()
        alert.title = title
        alert.message = message
        
        alert.addButton(withTitle: NSLocalizedString("title-ok", comment: "OK Button Title"))
        alert.show()
    }
    
    
    private func startCameraWithCompletionHandler(_ completion: @escaping CompletionWithError) {
        // Capture session
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        
        captureSession.beginConfiguration()
        
        // Obtain back facing camera
        captureDevice = self.cameraDeviceForPosition(.back)
        if captureDevice == nil {
            let message = NSLocalizedString("message-back-camera-not-found", comment: "Error message back camera - not found")
            let title = NSLocalizedString("title-back-camera-not-found", comment: "Error title back camera - not found")
            self.showErrorMessage(message, title: title)
            return
        }
        
        let deviceInput: AVCaptureDeviceInput
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            NSLog("This error should be handled appropriately in your app -- obtain device input: \(error)")
            let message = NSLocalizedString("message-back-camera-open-failed", comment: "Error message back camera - can't open.")
            let title = NSLocalizedString("title-back-camera-open-failed", comment: "Error title for back camera - can't open.")
            self.showErrorMessage(message, title: title)
            return
        }
        captureSession.addInput(deviceInput)
        
        // Still image output
        let stillImageOutput = AVCaptureStillImageOutput()
        self.stillImageOutput = stillImageOutput
        stillImageOutput.outputSettings = [
            // JPEG output
            AVVideoCodecKey: AVVideoCodecJPEG
            /*
            * Or instead of JPEG, we can use one of the following pixel formats:
            *
            // BGRA
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
            *
            // 420f output
            (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            *
            */
        ]
        captureSession.addOutput(stillImageOutput)
        
        // Capture preview
        _cameraPreviewView.configureCaptureSession(captureSession, captureOutput: stillImageOutput)
        
        // Configure for high resolution still image photography
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        
        // Track the device's active format (we don't change this later)
        captureDeviceFormat = captureDevice!.activeFormat
        
        captureSession.commitConfiguration()
        
        // Start the AV session
        captureSession.startRunning()
        
        // We make sure not to exceed the maximum number of supported brackets
        maxBracketCount = stillImageOutput.maxBracketedCaptureStillImageCount
        
        // Construct capture bracket settings and warmup
        self.prepareBracketsWithCompletionHandler(completion)
    }
    
    
    private func prepareBracketsWithCompletionHandler(_ completion: @escaping CompletionWithError) {
        // Construct the list of brackets
        switch _bracketModeControl.selectedSegmentIndex {
        case 0:
            NSLog("Configuring auto-exposure brackets...")
            bracketSettings = self.exposureBrackets()
            
        case 1:
            NSLog("Configuring duration/ISO brackets...")
            bracketSettings = self.durationISOBrackets()
        default:
            break
        }
        
        // Prime striped image buffer
        let dimensions = CMVideoFormatDescriptionGetDimensions(captureDevice!.activeFormat.formatDescription)
        imageStripes = StripedImage(forSize: CGSize(width: CGFloat(dimensions.width), height: CGFloat(dimensions.height)), stripWidth: CGFloat(dimensions.width)/12.0, stride: bracketSettings!.count)
        
        // Warm up bracketed capture
        NSLog("Warming brackets: %@", bracketSettings!)
        let connection = stillImageOutput!.connection(withMediaType: AVMediaTypeVideo)
        stillImageOutput?.prepareToCaptureStillImageBracket(from: connection,
            withSettingsArray: bracketSettings) {
                prepared, error in
                
                completion(prepared, error)
        }
    }
    
    
    private func exposureBrackets() -> [AVCaptureBracketedStillImageSettings] {
        var brackets = [AVCaptureBracketedStillImageSettings]()
        brackets.reserveCapacity(maxBracketCount)
        
        // Fixed bracket settings
        let fixedBracketCount = 3
        let biasValues: [Float] = [
            -2.0, 0.0, +2.0,
        ]
        
        for index in 0..<min(fixedBracketCount, maxBracketCount) {
            
            let biasValue = biasValues[index]
            
            let settings = AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(withExposureTargetBias: biasValue)
            brackets.append(settings!)
        }
        
        return brackets
    }
    
    
    private func durationISOBrackets() -> [AVCaptureBracketedStillImageSettings] {
        var brackets: [AVCaptureBracketedStillImageSettings] = []
        brackets.reserveCapacity(maxBracketCount)
        
        // ISO and Duration are hardware dependent
        NSLog("Camera device ISO range: [%.2f, %.2f]", captureDeviceFormat!.minISO, captureDeviceFormat!.maxISO)
        NSLog("Camera device Duration range: [%.4f, %.4f]", CMTimeGetSeconds(captureDeviceFormat!.minExposureDuration), CMTimeGetSeconds(captureDeviceFormat!.maxExposureDuration))
        
        // Fixed bracket settings
        let fixedBracketCount = 3
        let ISOValues: [Float] = [
            50, 60, 500,
        ]
        let durationSecondsValues: [Float64] = [
            0.250, 0.050, 0.005,
        ]
        
        for index in 0..<min(fixedBracketCount, maxBracketCount) {
            
            // Clamp fixed settings to the device limits
            let ISO = CLAMP(
                ISOValues[index],
                lo: captureDeviceFormat!.minISO,
                hi: captureDeviceFormat!.maxISO
            )
            
            let durationSeconds = CLAMP(
                durationSecondsValues[index],
                lo: CMTimeGetSeconds(captureDeviceFormat!.minExposureDuration),
                hi: CMTimeGetSeconds(captureDeviceFormat!.maxExposureDuration)
            )
            let duration = CMTimeMakeWithSeconds(durationSeconds, 1000)
            
            // Create bracket settings
            let settings = AVCaptureManualExposureBracketedStillImageSettings.manualExposureSettings(withExposureDuration: duration, iso: ISO)
            brackets.append(settings!)
        }
        
        return brackets
    }
    
    
    private func performBrackedCaptureWithCompletionHandler(_ completion: @escaping CompletionWithImage) {
        // Number of brackets to capture
        var todo = bracketSettings!.count
        
        // Number of failed bracket captures
        var failed = 0
        
        NSLog("Performing bracketed capture: %@", bracketSettings!)
        guard
            let stillImageOutput = stillImageOutput,
            let connection = stillImageOutput.connection(withMediaType: AVMediaTypeVideo)
            else {
            print("stillImageOutput is not ready yet")
            return
        }
        stillImageOutput.captureStillImageBracketAsynchronously(from: connection, withSettingsArray: bracketSettings!) {
            sampleBuffer, stillImageSettings, error in
            todo -= 1

            if let error = error {
                NSLog("This error should be handled appropriately in your app -- Bracket \(stillImageSettings?.description ?? "settings-nil") ERROR: \(error)")
                
                failed += 1
            } else {
                NSLog("Bracket \(stillImageSettings?.description ?? "settings-nil")")
                
                // Process this sample buffer while we wait for the next bracketed image to be captured.
                // You would insert your own HDR algorithm here.
                guard let sampleBuffer = sampleBuffer else {
                    print("something odd in sampleBuffer")
                    return
                }
                self.imageStripes!.addSampleBuffer(sampleBuffer)
            }
            
            // Return the rendered image strip when the capture completes
            if todo == 0 {
                NSLog("All %d bracket(s) have been captured %@ error.", self.bracketSettings!.count, (failed != 0) ? "with" : "without")
                
                // This demo is restricted to portrait orientation for simplicity, where we hard-code the rendered striped image orientation.
                let image: UIImage? =
                failed == 0 ?
                    self.imageStripes!.imageWithOrientation(.right) :
                nil
                
                // Don't assume we're on the main thread
                DispatchQueue.main.async {
                    completion(image)
                }
            }
        }
    }
    
    
    @IBAction private func _bracketModeDidChange(_ sender: AnyObject) {
        self.userInterfaceEnabled = false
        
        // Prepare for the new bracket settings
        self.prepareBracketsWithCompletionHandler { success, error in
            
            self.userInterfaceEnabled = true
        }
    }
    
    @IBAction private func _cameraShutterDidPress(_ sender: AnyObject) {
        if !captureSession!.isRunning {
            return
        }
        
        self.userInterfaceEnabled = false
        
        self.performBrackedCaptureWithCompletionHandler {image in
            
            let controller = ImageViewController(image: image)
            controller.delegate = self
            controller.title = NSLocalizedString("title-bracket-stripes", comment: "Bracket Viewer Title")
            
            let navController = UINavigationController(rootViewController: controller)
            navController.modalTransitionStyle = .coverVertical
            
            self.present(navController, animated: true, completion: nil)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.userInterfaceEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.startCameraWithCompletionHandler {success, error in
            if success {
                self.userInterfaceEnabled = true
            } else {
                NSLog("This error should be handled appropriately in your app -- start camera completion: \(error?.localizedDescription ?? "nil")")
            }
        }
    }
    //###
    override func viewDidDisappear(_ animated: Bool) {
        stopCamera()
        super.viewDidDisappear(animated)
    }
    //###
    private func stopCamera() {
        _cameraPreviewView.unconfigureCaptureSession()
        self.stillImageOutput = nil
    }
    
    
    //MARK: - ImageViewDelegate
    
    func imageViewControllerDidFinish(_ controller: ImageViewController) {
        controller.dismiss(animated: true) {
            self.userInterfaceEnabled = true
        }
    }
    
}
