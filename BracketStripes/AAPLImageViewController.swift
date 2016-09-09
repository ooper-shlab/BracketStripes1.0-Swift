//
//  AAPLImageViewController.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/07.
//
//
/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:

         Photo view controller

 */


import UIKit

@objc(AAPLImageViewDelegate)
protocol ImageViewDelegate {

    func imageViewControllerDidFinish(_ controller: ImageViewController)

}


@objc(AAPLImageViewController)
class ImageViewController: UIViewController {

    weak var delegate: ImageViewDelegate?

    
    private var image: UIImage?
    private var imageView: ZoomImageView?

    
    // Designated initializer
    init(image: UIImage?) {

        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    override func loadView() {
        super.loadView()

        imageView = ZoomImageView()
        imageView!.image = image
        imageView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        self.automaticallyAdjustsScrollViewInsets = false
        self.view = imageView!

        let iosBlueColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
        self.navigationController?.navigationBar.tintColor = iosBlueColor

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(ImageViewController._done(_:)))
    }

    
    func _done(_ sender: AnyObject) {
        delegate?.imageViewControllerDidFinish(self)
    }

}
