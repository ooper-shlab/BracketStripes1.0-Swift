//
//  AAPLCapturePreviewView.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/06.
//
//
/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:

         Camera preview view, with automatic "flash" animation

 */

import UIKit
import AVFoundation


// Keypath for when still image capture is taking place
let kCapturingStillImageKeypath = "capturingStillImage"


@objc(AAPLCapturePreviewView)
class CapturePreviewView : UIView {
    private var flashView: UIView?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var captureOutput: AVCaptureOutput?
    
    
    func configureCaptureSession(captureSession: AVCaptureSession, captureOutput: AVCaptureOutput) {
        if previewLayer != nil {
            previewLayer!.removeFromSuperlayer()
            previewLayer = nil
        }
        
        // Add preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer!.videoGravity = AVLayerVideoGravityResizeAspect
        previewLayer!.frame = self.bounds
        self.layer.addSublayer(previewLayer)
        
        // Visually animate still image capture
        self.captureOutput = captureOutput
        self.captureOutput!.addObserver(self, forKeyPath: kCapturingStillImageKeypath, options: .New, context: nil)
    }
    
    
    deinit {
        self.captureOutput!.removeObserver(self, forKeyPath: kCapturingStillImageKeypath)
    }
    
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        // Still image capture state
        if object === self.captureOutput &&
            keyPath == kCapturingStillImageKeypath {
                
                let value = change[NSKeyValueChangeNewKey]! as! Bool
                self.animateVisualShutter(value)
                return
        }
        
        // Unhandled, pass up the chain
        super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
    }
    
    
    private func animateVisualShutter(start: Bool) {
        if start {
            flashView?.removeFromSuperview()
            
            flashView = UIView(frame: self.bounds)
            flashView!.backgroundColor = UIColor.whiteColor()
            flashView!.alpha = 0.0
            self.addSubview(flashView!)
            
            UIView.animateWithDuration(0.1) {
                self.flashView!.alpha = 1.0
            }
        } else {
            
            UIView.animateWithDuration(0.1, animations: {
                self.flashView!.alpha = 0.0
                }) {finished in
                    self.flashView!.removeFromSuperview()
                    self.flashView = nil
            }
        }
    }
    
}