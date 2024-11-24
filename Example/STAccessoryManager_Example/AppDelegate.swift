//
//  AppDelegate.swift
//  STAccessoryManager_Example
//
//  Created by coder on 2024/11/15.
//

import UIKit
import DoraemonKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        DoraemonManager.shareInstance().install()
        DoraemonManager.shareInstance().showDoraemon()
        return true
    }
}

