//
//  AAPLStripedImage.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/07.
//
//
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Implements a composite image constructed of CMSampleBuffer stripes.
 */

import UIKit
import CoreMedia
import ImageIO
import CoreGraphics

@objc(StripedImage)
class StripedImage : NSObject {
    
    
    // Size of the rendered striped image
    private var imageSize: CGSize = CGSize()
    
    // Size of a stripe
    private var stripeSize: CGSize = CGSize()
    
    // Number of stripes before they repeat in the rendered image
    private var stride: Int = 0
    
    // Current stripe index
    private var stripeIndex: Int = 0
    
    // Bitmap context we render into
    private var renderContext: CGContext?
    
    
    private func prepareImageOfSize(_ size: CGSize) {
        let bitsPerComponent: size_t = 8
        let width = size_t(size.width)
        let paddedWidth = (width + 15) & ~15
        let bytesPerPixel: size_t = 4
        let bytesPerRow = paddedWidth * bytesPerPixel
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        renderContext = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
    }
    
    
    private func createImageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> CGImage? {
        var image: CGImage? = nil
        
        let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        let subType = CMFormatDescriptionGetMediaSubType(formatDescription!)
        
        let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)
        
        if blockBuffer != nil {
            
            assert(subType == FourCharCode(kCMVideoCodecType_JPEG), "Block buffer must be JPEG encoded.")
            
            // Sample buffer is a JPEG compressed image
            var lengthAtOffset: size_t = 0
            var length: size_t = 0
            var jpegBytes: UnsafeMutablePointer<Int8>? = nil
            
            
            if CMBlockBufferGetDataPointer(blockBuffer!, 0, &lengthAtOffset, &length, &jpegBytes) == OSStatus(kCMBlockBufferNoErr) &&
                lengthAtOffset == length {
                    
                    let jpegData = NSData(bytes: UnsafePointer<Int8>(jpegBytes), length: Int(length))
                    let imageSource = CGImageSourceCreateWithData(jpegData, nil)
                    
                    let decodeOptions: NSDictionary = [
                        kCGImageSourceShouldAllowFloat as NSString : false,
                        kCGImageSourceShouldCache as NSString : false,
                    ]
                    image = CGImageSourceCreateImageAtIndex(imageSource!, 0, decodeOptions)
                    
            }
        } else {
            
            assert(subType == FourCharCode(kCVPixelFormatType_32BGRA), "Image buffer must be BGRA encoded.")
            
            // Sample buffer is a BGRA uncompressed image
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            CVPixelBufferLockBaseAddress(imageBuffer!, .readOnly)
            
            let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer!, 0)
            
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!)
            let bitsPerComponent: size_t = 8
            let width = CVPixelBufferGetWidth(imageBuffer!)
            let height = CVPixelBufferGetHeight(imageBuffer!)
            
            let bitmapContext = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue)
            image = bitmapContext!.makeImage()
            
            CVPixelBufferUnlockBaseAddress(imageBuffer!, .readOnly)
            
        }
        
        return image
    }
    
    
    // Designated initializer
    init(forSize size: CGSize, stripWidth: CGFloat, stride: Int) {
        super.init()
        
        self.imageSize = size
        self.stride = stride
        
        self.stripeSize = CGSize(
            width: stripWidth,
            height: size.height
        )
        
        self.prepareImageOfSize(size)
    }
    
    
    // The final rendered strip
    func imageWithOrientation(_ orientation: UIImageOrientation) -> UIImage? {
        let scale = UIScreen.main.scale
        
        guard let cgImage = renderContext?.makeImage() else {return nil}
        let image = UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        
        return image
    }
    
    
    // Add an image to the strip
    // sampleBuffer must be a JPEG or BGRA image
    func addSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard let renderContext = renderContext else {
            print("renderContext is not ready yet")
            return
        }
        let renderStartTime = Date()
        
        guard let image = self.createImageFromSampleBuffer(sampleBuffer) else {
            print("failed to create image")
            return
        }
        
        let imageRect = CGRect(
            x: 0, y: 0,
            width: CGFloat(image.width), height: CGFloat(image.height)
        )
        
        var maskRects = [CGRect]()
        var maskRect = CGRect(
            x: stripeSize.width * CGFloat(stripeIndex), y: 0,
            width: stripeSize.width, height: stripeSize.height
        )
        
        // Scan the input sample buffer across the rendered image until we can't squeeze in any more...
        while maskRect.origin.x < imageSize.width {
            
            maskRects.append(maskRect)
            
            // Move the mask to the right
            maskRect.origin.x += stripeSize.width * CGFloat(stride)
        }
        
        // Convert maskRects NSMutableArray to something Core Graphics can use
        
        // Perform the render
        renderContext.saveGState()
        
        renderContext.clip(to: maskRects)
        renderContext.draw(image, in: imageRect)
        
        renderContext.restoreGState()
        
        let renderDuration = Date().timeIntervalSince(renderStartTime)
        NSLog(String(format: "Render time for contributor %d: %.3f msec", stripeIndex, renderDuration * 1e3))
        
        // Move to the next stripe, allowing wrapping
        stripeIndex = (stripeIndex + 1) % stride
    }
    
}
