//
//  STAccessoryManagerInsterFace.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

import Combine

/// 业务结果
public class STAccessoryWorkResult<T> : NSObject {
    /// 业务应答
    public internal(set) var status: Bool = true
    /// 设备标识
    public internal(set) var devSerialNumber: String = ""
    /// 状态描述
    public internal(set) var workDes: String = "default work result description"
    
    public var workData: T?
    
    internal override init() {}
    
    init(status: Bool = true, devSerialNumber: String = "", workDes: String = "", workData: T? = nil) {
        self.status = status
        self.devSerialNumber = devSerialNumber
        self.workDes = workDes
        self.workData = workData
    }
    
    public func jsonString() -> String {
        return encodeToJsonString()
    }
    
    public func jsonInfo() -> [String:Any] {
        return encodeToJsonDict()
    }
}

extension STAccessoryWorkResult: Encodable {
    // 实现了 `Encodable` 协议
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(status, forKey: .status)
        try container.encode(devSerialNumber, forKey: .devSerialNumber)
        try container.encode(workDes, forKey: .workDes)
        
        // 如果 workData 存在且能够编码，尝试编码 workData
        
        var workDataEncoder = encoder.singleValueContainer()
        if let workData = workData as? Encodable {
            try workDataEncoder.encode(workData)
        } else {
            STLog.warning("Work data is not Encodable")
        }
    }
    
    // 用来定义编码的字段名称，注意：这里我们使用了蛇形命名风格
    private enum CodingKeys: String, CodingKey {
        case status
        case devSerialNumber
        case workDes
        case workData
    }
}

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
    func accessoryHander(devSerialNumber: String, complete: STAComplete<STAccesoryHandlerInterface>?)
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

