//
//  AAPLCameraViewController.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/07.
//
//
/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:

         Camera view controller

 */


import UIKit
import AVFoundation
import CoreMedia


// Completion handler prototypes
typealias Completion = (Bool)->Void
typealias CompletionWithError = (Bool, NSError?)->Void
typealias CompletionWithImage = (UIImage?)->Void


@objc(AAPLCameraViewController)
class CameraViewController: UIViewController, ImageViewDelegate {
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    // Capture
    private var captureSession: AVCaptureSession?
    private var captureDevice: AVCaptureDevice?
    private var captureDeviceFormat: AVCaptureDeviceFormat?
    private var stillImageOutput: AVCaptureStillImageOutput?
    
    // Brackets
    private var maxBracketCount: Int = 0
    private var bracketSettings: NSArray?
    
    // UI
    @IBOutlet private var _cameraPreviewView: CapturePreviewView!
    @IBOutlet private var _cameraShutterButton: UIButton!
    @IBOutlet private var _bracketModeControl: UISegmentedControl!
    
    // Striped rendered brackets
    private var imageStripes: StripedImage?
    
    
    // Convenience for enable/disable UI controls
    private var userInterfaceEnabled: Bool {
        set {
            _cameraShutterButton?.enabled = newValue
            _bracketModeControl?.enabled = newValue
        }
        
        
        get {
            return _cameraShutterButton.enabled
            
        }
    }
    
    
    private func cameraDeviceForPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        for device in AVCaptureDevice.devices() as! [AVCaptureDevice] {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    
    private func showErrorMessage(message: String, title: String) {
        let alert = UIAlertView()
        alert.title = title
        alert.message = message
        
        alert.addButtonWithTitle(NSLocalizedString("title-ok", comment: "OK Button Title"))
        alert.show()
    }
    
    
    private func startCameraWithCompletionHandler(completion: CompletionWithError) {
        // Capture session
        captureSession = AVCaptureSession()
        
        captureSession!.beginConfiguration()
        
        // Obtain back facing camera
        captureDevice = self.cameraDeviceForPosition(.Back)
        if captureDevice == nil {
            let message = NSLocalizedString("message-back-camera-not-found", comment: "Error message back camera - not found")
            let title = NSLocalizedString("title-back-camera-not-found", comment: "Error title back camera - not found")
            self.showErrorMessage(message, title: title)
            return
        }
        
        var error: NSError? = nil
        let deviceInput = AVCaptureDeviceInput(device: captureDevice, error: &error)
        if error != nil {
            NSLog("This error should be handled appropriately in your app -- obtain device input: %@", error!)
            let message = NSLocalizedString("message-back-camera-open-failed", comment: "Error message back camera - can't open.")
            let title = NSLocalizedString("title-back-camera-open-failed", comment: "Error title for back camera - can't open.")
            self.showErrorMessage(message, title: title)
            return
        }
        captureSession?.addInput(deviceInput)
        
        // Still image output
        stillImageOutput = AVCaptureStillImageOutput()
        stillImageOutput!.outputSettings = [
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
        captureSession!.addOutput(stillImageOutput)
        
        // Capture preview
        _cameraPreviewView.configureCaptureSession(captureSession!, captureOutput: stillImageOutput!)
        
        // Configure for high resolution still image photography
        captureSession!.sessionPreset = AVCaptureSessionPresetPhoto
        
        // Track the device's active format (we don't change this later)
        captureDeviceFormat = captureDevice!.activeFormat
        
        captureSession!.commitConfiguration()
        
        // Start the AV session
        captureSession!.startRunning()
        
        // We make sure not to exceed the maximum number of supported brackets
        println(NSStringFromClass(stillImageOutput!.dynamicType))
        println(stillImageOutput!.respondsToSelector("maxBracketedCaptureStillImageCount"))
        maxBracketCount = stillImageOutput!.maxBracketedCaptureStillImageCount//.maxBracketedCaptureStillImageCount
        
        // Construct capture bracket settings and warmup
        self.prepareBracketsWithCompletionHandler(completion)
    }
    
    
    private func prepareBracketsWithCompletionHandler(completion: CompletionWithError) {
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
        imageStripes = StripedImage(forSize: CGSizeMake(CGFloat(dimensions.width), CGFloat(dimensions.height)), stripWidth: CGFloat(dimensions.width)/12.0, stride: bracketSettings!.count)
        
        // Warm up bracketed capture
        NSLog("Warming brackets: %@", bracketSettings!)
        let connection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)
        stillImageOutput?.prepareToCaptureStillImageBracketFromConnection(connection,
            withSettingsArray: bracketSettings as! [AnyObject]) {
                prepared, error in
                
                completion(prepared, error)
        }
    }
    
    
    private func exposureBrackets() -> [AVCaptureAutoExposureBracketedStillImageSettings] {
        var brackets = [AVCaptureAutoExposureBracketedStillImageSettings]()
        brackets.reserveCapacity(maxBracketCount)
        
        // Fixed bracket settings
        let fixedBracketCount = 3
        let biasValues: [Float] = [
            -2.0, 0.0, +2.0,
        ]
        
        for index in 0..<min(fixedBracketCount, maxBracketCount) {
            
            let biasValue = biasValues[index]
            
            let settings = AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettingsWithExposureTargetBias(biasValue)
            brackets.append(settings)
        }
        
        return brackets
    }
    
    
    private func durationISOBrackets() -> [AVCaptureManualExposureBracketedStillImageSettings] {
        var brackets = [AVCaptureManualExposureBracketedStillImageSettings]()
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
                captureDeviceFormat!.minISO,
                captureDeviceFormat!.maxISO
            )
            
            let durationSeconds = CLAMP(
                durationSecondsValues[index],
                CMTimeGetSeconds(captureDeviceFormat!.minExposureDuration),
                CMTimeGetSeconds(captureDeviceFormat!.maxExposureDuration)
            )
            let duration = CMTimeMakeWithSeconds(durationSeconds, 1000)
            
            // Create bracket settings
            let settings = AVCaptureManualExposureBracketedStillImageSettings.manualExposureSettingsWithExposureDuration(duration, ISO: ISO)
            brackets.append(settings)
        }
        
        return brackets
    }
    
    
    private func performBrackedCaptureWithCompletionHandler(completion: CompletionWithImage) {
        // Number of brackets to capture
        var todo = bracketSettings!.count
        
        // Number of failed bracket captures
        var failed = 0
        
        NSLog("Performing bracketed capture: %@", bracketSettings!)
        let connection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo)
        stillImageOutput!.captureStillImageBracketAsynchronouslyFromConnection(connection, withSettingsArray: bracketSettings! as [AnyObject]) {
            sampleBuffer, stillImageSettings, error in
            --todo
            
            if error == nil {
                NSLog("Bracket %@", stillImageSettings)
                
                // Process this sample buffer while we wait for the next bracketed image to be captured.
                // You would insert your own HDR algorithm here.
                self.imageStripes!.addSampleBuffer(sampleBuffer)
            } else {
                NSLog("This error should be handled appropriately in your app -- Bracket %@ ERROR: %@", stillImageSettings, error!)
                
                ++failed
            }
            
            // Return the rendered image strip when the capture completes
            if todo == 0 {
                NSLog("All %d bracket(s) have been captured %@ error.", self.bracketSettings!.count, (failed != 0) ? "with" : "without")
                
                // This demo is restricted to portrait orientation for simplicity, where we hard-code the rendered striped image orientation.
                let image: UIImage? =
                failed == 0 ?
                    self.imageStripes!.imageWithOrientation(.Right) :
                nil
                
                // Don't assume we're on the main thread
                dispatch_async(dispatch_get_main_queue()) {
                    completion(image)
                }
            }
        }
    }
    
    
    @IBAction private func _bracketModeDidChange(sender: AnyObject) {
        self.userInterfaceEnabled = false
        
        // Prepare for the new bracket settings
        self.prepareBracketsWithCompletionHandler { success, error in
            
            self.userInterfaceEnabled = true
        }
    }
    
    @IBAction private func _cameraShutterDidPress(sender: AnyObject) {
        if !captureSession!.running {
            return
        }
        
        self.userInterfaceEnabled = false
        
        self.performBrackedCaptureWithCompletionHandler {image in
            
            let controller = ImageViewController(image: image)
            controller.delegate = self
            controller.title = NSLocalizedString("title-bracket-stripes", comment: "Bracket Viewer Title")
            
            let navController = UINavigationController(rootViewController: controller)
            navController.modalTransitionStyle = .CoverVertical
            
            self.presentViewController(navController, animated: true, completion: nil)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userInterfaceEnabled = false
        
        self.startCameraWithCompletionHandler() {success, error in
            if success {
                self.userInterfaceEnabled = true
            } else {
                NSLog("This error should be handled appropriately in your app -- start camera completion: %@", error!)
            }
        }
    }
    
    
    //MARK: - ImageViewDelegate
    
    func imageViewControllerDidFinish(controller: ImageViewController) {
        controller.dismissViewControllerAnimated(true) {
            self.userInterfaceEnabled = true
        }
    }
    
}