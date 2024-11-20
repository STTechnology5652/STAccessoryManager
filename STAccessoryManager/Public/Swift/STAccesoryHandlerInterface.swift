//
//  STAccesoryHandlerInterface.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

public class STAccesoryCmdData {
   public let tag: UInt8
   public let data: Data
    
    // 解析器
    var responseHandler: Any?
    
    public init(tag: UInt8, data: Data) {
        self.tag = tag
        self.data = data
    }
}

/// 操作设备的接口
public protocol STAccesoryHandlerInterface: NSObjectProtocol {
    func getNextCmdTag() -> UInt8
    @discardableResult func openSteam(_ open: Bool, protocol: String?) async -> STAccessoryWorkResult<Any>
    @discardableResult func sendCommand(_ cmdData:STAccesoryCmdData, protocol: String?) -> STAccessoryWorkResult<Any>
}

protocol STAccesoryHandlerInterface_pri: STAccesoryHandlerInterface {
    func deviceDisconnected(dev: EAAccessory)
}

