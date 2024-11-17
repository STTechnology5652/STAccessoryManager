//
//  STAccessoryManagerInsterFace.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

import Combine

/// 业务结果
@objcMembers
public class STAccessoryWorkResult: NSObject {
    /// 业务状态
    public internal(set) var status: Bool = true
    /// 设备标识
    public internal(set) var devSerialNumber: String = ""
    /// 状态描述
    public internal(set) var workDes: String = "default work result description"
    
    internal override init() {}
    
    init(status: Bool, devSerialNumber: String, workDes: String) {
        self.status = status
        self.devSerialNumber = devSerialNumber
        self.workDes = workDes
    }
    
    public func jsonString() -> String {
        return encodeToJsonString()
    }
    
    public func jsonInfo() -> [String:Any] {
        return encodeToJsonDict()
    }
}

extension STAccessoryWorkResult: Encodable {}

//MARK: - STAccessoryManager 对外接口
/// STAccessoryManager 对外接口
public protocol STAccessoryManagerInsterFace {
    /// 单例方法
    /// - Returns: 单例
    @discardableResult static func share() -> STAccessoryManager
    
    
    var connectedAccessory: [EAAccessory] {get}

    /// 配置代理
    /// - Parameter delegate: 代理
    /// - Returns: 单例
    @discardableResult func config(delegate: NSObject & STAccessoryConnectDelegate) -> Self
    
    /// 获取所有代理
    /// - Returns: 代理数组
    func allDelegates() -> [STAccessoryConnectDelegate]
    
    /// 设备句柄
    /// - Parameters:
    ///   - devSerialNumber: 设备标识
    ///   - protocolStr: 设备协议标识
    /// - Returns: 设备句柄
    func accessoryHander(devSerialNumber: String) async -> STAccesoryHandlerInterface?
}

//MARK: - STAccessoryManager 连接代理
/// STAccessoryManager 连接代理
@objc public protocol STAccessoryConnectDelegate {
    /// 连接到新设备
    /// - Parameter device: 设备对象
    @objc optional func didConnect(device: EAAccessory)
    
    /// 有设备断开
    /// - Parameter device: 设备对象
    @objc optional func didDisconnect(device: EAAccessory)
}


//MARK: - STAccessoryManager 内部 json 辅助方法
extension Encodable {
    func encodeToJsonDict() -> [String: Any] {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(self)
            if let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                return jsonDict
            } else {
                STLog.err("Failed to convert JSON data to dictionary.")
                return [String: Any]()
            }
        } catch {
            STLog.err("Encoding or JSONSerialization failed with error: \(error)")
            return [String: Any]()
        }
    }
    
    func encodeToJsonString() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted // 可选：让输出的 JSON 字符串格式化为更易读的形式
        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            } else {
                STLog.err("Failed to convert Data to String.")
                return ""
            }
        } catch {
            STLog.err("Encoding failed with error: \(error)")
            return ""
        }
    }
}

