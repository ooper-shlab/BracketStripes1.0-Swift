//
//  AppDelegate.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/06.
//
//
/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:

         Application delegate

 */

import UIKit

@UIApplicationMain
@objc(AppDelegate)
class AppDelegate : UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject : AnyObject]?) -> Bool {
        UIView.appearance().tintColor = UIColor.yellowColor()
        
        return true
    }
    
}
