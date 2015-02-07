//
//  AAPLZoomImageView.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/06.
//
//
/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:

         Zoomable image view

 */
import UIKit


@objc(AAPLZoomImageView)
class ZoomImageView: UIView, UIScrollViewDelegate {
    
    var image: UIImage? {
        didSet {
            didSetImage(oldValue)
        }
    }
    
    
    private var needsSizing: Bool = false
    
    // UI
    private var scrollView: UIScrollView?
    private var imageView: UIImageView?
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.whiteColor()
        
        scrollView = UIScrollView(frame: CGRectZero)
        scrollView!.delegate = self
        self.addSubview(scrollView!)
        
        imageView = UIImageView(frame: CGRectZero)
        scrollView!.addSubview(imageView!)
    }
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        scrollView!.frame = self.bounds
        
        if needsSizing {
            self.performSizing()
        }
    }
    
    
    private func didSetImage(oldValue: UIImage?) {
        imageView!.image = image
        
        if image != nil {
            imageView!.sizeToFit()
            
            needsSizing = true
            self.setNeedsLayout()
        }
    }
    
    
    private func performSizing() {
        scrollView!.zoomScale = 1.0
        scrollView!.minimumZoomScale = 1.0
        scrollView!.maximumZoomScale = 1.0
        
        let image = imageView!.image
        
        scrollView!.contentSize = image!.size
        
        if image != nil {
            
            // Aspect fit
            let aspect = image!.size.width / image!.size.height
            
            if aspect * self.bounds.size.height > self.bounds.size.width {
                // Width constrains us
                let zoomScale = self.bounds.size.width / image!.size.width
                scrollView!.zoomScale = zoomScale
                scrollView!.minimumZoomScale = zoomScale
            } else {
                // Height constrains us
                let zoomScale = self.bounds.size.height / image!.size.height
                scrollView!.zoomScale = zoomScale
                scrollView!.minimumZoomScale = zoomScale
            }
        }
        
        self.centerImageInScrollView()
        
        needsSizing = false
    }
    
    
    private func centerImageInScrollView() {
        let boundsSize = scrollView!.bounds.size
        var frameToCenter = imageView!.frame
        
        // Center horizontally
        if frameToCenter.size.width < boundsSize.width {
            
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2.0
        } else {
            
            frameToCenter.origin.x = 0.0
        }
        
        // Center vertically
        if frameToCenter.size.height < boundsSize.height {
            
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2.0
        } else {
            
            frameToCenter.origin.y = 0.0
        }
        
        imageView!.frame = frameToCenter
    }
    
    
    //MARK: - UIScrollViewDelegate
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        self.centerImageInScrollView()
    }
    
}