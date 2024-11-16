//
//  STAccessoryManager.swift
//  Pod
//
//  Created by coder on 2024/11/15.
//
// @_exported import XXXXXX //这个是为了对外暴露下层依赖的Pod

import ExternalAccessory

struct STModuleTag {
 static let AccessoryManager = "AccessoryManager"
}

@objc public protocol STAccessoryManagerDelegate {
    @objc optional func didConnect(device: EAAccessory)
    @objc optional func didDisconnect(device: EAAccessory)
}

@objc
public class STAccessoryManager: NSObject {
    private static let shareIns = STAccessoryManager()
    
    private var registedDevices = [String]()
    private var delegateArr: NSPointerArray = NSPointerArray.weakObjects()
    public private(set) var accessoryArr = [EAAccessory]()
    
    private override init() {
        super.init()
        initConfig()
    }
    
    deinit {
        let notCenter = NotificationCenter.default
        notCenter.removeObserver(self)
        EAAccessoryManager.shared().unregisterForLocalNotifications()
    }
    
    @discardableResult public func config(delegate: NSObject & STAccessoryManagerDelegate) -> Self {
        delegateArr.pointerFunctions
        delegateArr.addPointer(Unmanaged.passUnretained(delegate).toOpaque())
        return self
    }
    
    @discardableResult public static func share() -> STAccessoryManager {
        return STAccessoryManager.shareIns
    }
    
    public func allDelegates() -> [STAccessoryManagerDelegate] {
        var delegates: [STAccessoryManagerDelegate] = delegateArr.allObjects.flatMap { one in
            return one as? STAccessoryManagerDelegate
        }
        return delegates
    }
}

extension STAccessoryManager {
    private func initConfig() {
        // 加载UISupportedExternalAccessory属性以了解哪些protocolStrings在应用程序中注册
        if let arr: [String] = Bundle.main.object(forInfoDictionaryKey: "UISupportedExternalAccessoryProtocols") as? [String] {
            registedDevices.append(contentsOf: arr)
        }
        
        //配置监听
        let notCenter = NotificationCenter.default
        notCenter.addObserver(self, selector: #selector(self.didConnectDevice(_:)), name: .EAAccessoryDidConnect, object: nil)
        notCenter.addObserver(self, selector: #selector(self.didDisconenctDevice(_:)), name: .EAAccessoryDidDisconnect, object: nil)
        EAAccessoryManager.shared().registerForLocalNotifications()
    }
    
    @objc func didConnectDevice(_ noti: Notification) {
        STLog.info(tag: STModuleTag.AccessoryManager)
        guard let oneAccessory = noti.userInfo?[EAAccessoryKey] as? EAAccessory else {
            STLog.err(tag: STModuleTag.AccessoryManager, "no accessory")
            return
        }
        accessoryArr.append(oneAccessory)
        self.allDelegates().forEach { (oneDelegate: STAccessoryManagerDelegate) in
            oneDelegate.didConnect?(device: oneAccessory)
        }
    }
    
    @objc func didDisconenctDevice(_ noti: Notification) {
        STLog.info(tag: STModuleTag.AccessoryManager)
        guard let oneAccessory = noti.userInfo?[EAAccessoryKey] as? EAAccessory else {
            STLog.err(tag: STModuleTag.AccessoryManager, "no accessory")
            return
        }
        
        accessoryArr.removeAll { one in oneAccessory.serialNumber == one.serialNumber }
        self.allDelegates().forEach { (oneDelegate: STAccessoryManagerDelegate) in
            oneDelegate.didDisconnect?(device: oneAccessory)
        }
    }
}
