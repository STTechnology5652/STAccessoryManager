//
//  STAccessoryManager.swift
//  Pod
//
//  Created by coder on 2024/11/15.
//
// @_exported import XXXXXX //这个是为了对外暴露下层依赖的Pod

@_exported import ExternalAccessory

let STTag_STAccessoryModule = "STAccessoryModule"
let kTag_STStream = "STStream"

//MARK: - STAccessoryManager 实现
@objc
public class STAccessoryManager: NSObject {
    private static let shareIns = STAccessoryManager()
    private var registedDevices = [String]()
    private var delegateArr: NSPointerArray = NSPointerArray.weakObjects()
    private var deviceHandlerMap = [String: STAccesoryHandlerInterface]()
    
    public private(set) var connectedAccessory = [EAAccessory]()
    
    private override init() {
        super.init()
        initConfig()
    }
    
    deinit {
        let notCenter = NotificationCenter.default
        notCenter.removeObserver(self)
        EAAccessoryManager.shared().unregisterForLocalNotifications()
    }
}


//MARK: - 对外功能接口
extension STAccessoryManager: STAccessoryManagerInsterFace {
    @discardableResult public func config(delegate: NSObject & STAccessoryConnectDelegate) -> Self {
        delegateArr.pointerFunctions
        delegateArr.addPointer(Unmanaged.passUnretained(delegate).toOpaque())
        return self
    }
    
    @discardableResult public static func share() -> STAccessoryManager {
        return STAccessoryManager.shareIns
    }
    
    public func allDelegates() -> [STAccessoryConnectDelegate] {
        var delegates: [STAccessoryConnectDelegate] = delegateArr.allObjects.flatMap { one in
            return one as? STAccessoryConnectDelegate
        }
        return delegates
    }
    
    public func accessoryHander(devSerialNumber: String) async -> STAccesoryHandlerInterface? {
        guard let dev = device(devSerialNumber) else { // 对应设备已经断开连接
            let des = "设备已经断开连接"
            STLog.err(des)
            return nil
        }
        
        if let handler = deviceHandlerMap[devSerialNumber] { // 没有创建过session
            return handler
        } else {
            let hanler = STAccesoryHandler(devSerinalNumber: devSerialNumber)
            DispatchQueue.main.async {
                self.deviceHandlerMap[devSerialNumber] = hanler
            }
            return hanler
        }
    }
}

//MARK: - 内部接口
extension STAccessoryManager {
    func device(_ serialNumber: String) -> EAAccessory? {
        return connectedAccessory.filter{$0.serialNumber == serialNumber}.first
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
        let manager = EAAccessoryManager.shared()
        manager.registerForLocalNotifications()
        connectedAccessory = manager.connectedAccessories
    }
    
    @objc func didConnectDevice(_ noti: Notification) {
        guard let oneAccessory = noti.userInfo?[EAAccessoryKey] as? EAAccessory else {
            STLog.err(tag: STTag_STAccessoryModule, "no accessory")
            return
        }
        
        STLog.info(tag: STTag_STAccessoryModule, "\(oneAccessory.name) \(oneAccessory.serialNumber) \(oneAccessory.manufacturer) \(oneAccessory.modelNumber) \(oneAccessory.firmwareRevision) \(oneAccessory.hardwareRevision) \(oneAccessory.protocolStrings)")
        
        connectedAccessory = EAAccessoryManager.shared().connectedAccessories
        self.allDelegates().forEach { (oneDelegate: STAccessoryConnectDelegate) in
            oneDelegate.didConnect?(device: oneAccessory)
        }
    }
    
    @objc func didDisconenctDevice(_ noti: Notification) {
        guard let oneAccessory = noti.userInfo?[EAAccessoryKey] as? EAAccessory else {
            STLog.err(tag: STTag_STAccessoryModule, "no accessory")
            return
        }
        STLog.info(tag: STTag_STAccessoryModule, "\(oneAccessory.name) \(oneAccessory.serialNumber) \(oneAccessory.manufacturer) \(oneAccessory.modelNumber) \(oneAccessory.firmwareRevision) \(oneAccessory.hardwareRevision) \(oneAccessory.protocolStrings)")
        connectedAccessory = EAAccessoryManager.shared().connectedAccessories
        
        // 删除对应设备操作句柄， 句柄中也会知道设备断开连接，所以句柄中的设备通讯事件，由句柄自己处理
        DispatchQueue.main.async {
            self.deviceHandlerMap[oneAccessory.serialNumber] = nil
        }
        
        self.allDelegates().forEach { (oneDelegate: STAccessoryConnectDelegate) in
            oneDelegate.didDisconnect?(device: oneAccessory)
        }
    }
}
