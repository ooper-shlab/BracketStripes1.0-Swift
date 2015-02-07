//
//  AAPLStripedImage.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/07.
//
//
/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:

 Implements a composite image constructed of CMSampleBuffer stripes.

*/

import UIKit
import CoreMedia
import ImageIO
import CoreGraphics

@objc(AAPLStripedImage)
class StripedImage : NSObject {
    
    
    // Size of the rendered striped image
    private var imageSize: CGSize = CGSizeZero
    
    // Size of a stripe
    private var stripeSize: CGSize = CGSizeZero
    
    // Number of stripes before they repeat in the rendered image
    private var stride: Int = 0
    
    // Current stripe index
    private var stripeIndex: Int = 0
    
    // Bitmap context we render into
    private var renderContext: CGContextRef?
    
    
    private func prepareImageOfSize(size: CGSize) {
        let bitsPerComponent: size_t = 8
        let width = size_t(size.width)
        let paddedWidth = (width + 15) & ~15
        let bytesPerPixel: size_t = 4
        let bytesPerRow = paddedWidth * bytesPerPixel
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        renderContext = CGBitmapContextCreate(nil, UInt(size.width), UInt(size.height), bitsPerComponent, bytesPerRow, colorSpace, CGBitmapInfo(CGImageAlphaInfo.PremultipliedFirst.rawValue))
        
    }
    
    
    private func createImageFromSampleBuffer(sampleBuffer: CMSampleBufferRef) -> CGImageRef? {
        var image: CGImageRef? = nil
        
        var formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer)
        let subType = CMFormatDescriptionGetMediaSubType(formatDescription)
        
        let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)
        
        if blockBuffer != nil {
            
            assert(subType == FourCharCode(kCMVideoCodecType_JPEG), "Block buffer must be JPEG encoded.")
            
            // Sample buffer is a JPEG compressed image
            var lengthAtOffset: size_t = 0
            var length: size_t = 0
            var jpegBytes: UnsafeMutablePointer<Int8> = nil
            
            
            if CMBlockBufferGetDataPointer(blockBuffer, 0, &lengthAtOffset, &length, &jpegBytes) == OSStatus(kCMBlockBufferNoErr) &&
                lengthAtOffset == length {
                    
                    let jpegData = NSData(bytes: UnsafePointer<Int8>(jpegBytes), length: Int(length))
                    let imageSource = CGImageSourceCreateWithData(jpegData, nil)
                    
                    let decodeOptions: NSDictionary = [
                        kCGImageSourceShouldAllowFloat as NSString : false,
                        kCGImageSourceShouldCache as NSString : false,
                    ]
                    image = CGImageSourceCreateImageAtIndex(imageSource, 0, decodeOptions)
                    
            }
        } else {
            
            assert(subType == FourCharCode(kCVPixelFormatType_32BGRA), "Image buffer must be BGRA encoded.")
            
            // Sample buffer is a BGRA uncompressed image
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            CVPixelBufferLockBaseAddress(imageBuffer, 0)
            
            let baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0)
            
            let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
            let bitsPerComponent: size_t = 8
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            
            let bitmapContext = CGBitmapContextCreate(baseAddress, width, height, bitsPerComponent, bytesPerRow, colorSpace, (CGBitmapInfo.ByteOrder32Little | CGBitmapInfo(CGImageAlphaInfo.NoneSkipFirst.rawValue)))
            image = CGBitmapContextCreateImage(bitmapContext)
            
            CVPixelBufferUnlockBaseAddress(imageBuffer, 0)
            
        }
        
        return image
    }
    
    
    // Designated initializer
    init(forSize size: CGSize, stripWidth: CGFloat, stride: Int) {
        super.init()
        
        self.imageSize = size
        self.stride = stride
        
        self.stripeSize = CGSizeMake(
            stripWidth,
            size.height
        )
        
        self.prepareImageOfSize(size)
    }
    
    
    // The final rendered strip
    func imageWithOrientation(orientation: UIImageOrientation) -> UIImage? {
        let scale = UIScreen.mainScreen().scale
        
        let cgImage = CGBitmapContextCreateImage(renderContext)
        let image = UIImage(CGImage: cgImage, scale: scale, orientation: orientation)
        
        return image
    }
    
    
    // Add an image to the strip
    // sampleBuffer must be a JPEG or BGRA image
    func addSampleBuffer(sampleBuffer: CMSampleBufferRef) {
        let renderStartTime = NSDate()
        
        let image = self.createImageFromSampleBuffer(sampleBuffer)
        
        let imageRect = CGRectMake(
            0, 0,
            CGFloat(CGImageGetWidth(image)), CGFloat(CGImageGetHeight(image))
        )
        
        var maskRects = [CGRect]()
        var maskRect = CGRectMake(
            stripeSize.width * CGFloat(stripeIndex), 0,
            stripeSize.width, stripeSize.height
        )
        
        // Scan the input sample buffer across the rendered image until we can't squeeze in any more...
        while maskRect.origin.x < imageSize.width {
            
            maskRects.append(maskRect)
            
            // Move the mask to the right
            maskRect.origin.x += stripeSize.width * CGFloat(stride)
        }
        
        // Convert maskRects NSMutableArray to something Core Graphics can use
        let maskCount: Int = maskRects.count
        
        // Perform the render
        CGContextSaveGState(renderContext)
        
        CGContextClipToRects(renderContext, maskRects, UInt(maskCount))
        CGContextDrawImage(renderContext, imageRect, image)
        
        CGContextRestoreGState(renderContext)
        
        let renderDuration = NSDate().timeIntervalSinceDate(renderStartTime)
        NSLog("Render time for contributor %d: %.3f msec", stripeIndex, renderDuration * 1e3)
        
        // Move to the next stripe, allowing wrapping
        stripeIndex = (stripeIndex + 1) % stride
    }
    
}
