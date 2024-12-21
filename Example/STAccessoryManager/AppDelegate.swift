//
//  AppDelegate.swift
//  STAccessoryManager_Example
//
//  Created by coder on 2024/11/15.
//

import STABaseUI

#if K_BETA
import DoraemonKit
#endif

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 初始化window
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let maiVC = ViewController()
        // 设置根视图控制器
        let rootNav = STABaseNav(rootViewController: maiVC)
        window?.rootViewController = rootNav
        
        // 显示window
        window?.makeKeyAndVisible()
        
#if K_BETA
        // 初始化调试工具
        DoraemonManager.shareInstance().install()
        DoraemonManager.shareInstance().showDoraemon()
#endif
        
        return true
    }
}

