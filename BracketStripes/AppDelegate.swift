//
//  AppDelegate.swift
//  BracketStripes
//
//  Translated by OOPer in cooperation with shlab.jp, on 2014/10/06.
//
//
/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information

 Abstract:
 Application delegate
 */

import UIKit

@UIApplicationMain
@objc(AppDelegate)
class AppDelegate : UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        UIView.appearance().tintColor = UIColor.yellow
        
        return true
    }
    
}
