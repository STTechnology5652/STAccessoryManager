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
        
        // 初始化window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // 设置根视图控制器
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootViewController = storyboard.instantiateInitialViewController()
        window?.rootViewController = rootViewController
        
        // 显示window
        window?.makeKeyAndVisible()
        
        // 初始化调试工具
        DoraemonManager.shareInstance().install()
        DoraemonManager.shareInstance().showDoraemon()
        
        return true
    }
}

