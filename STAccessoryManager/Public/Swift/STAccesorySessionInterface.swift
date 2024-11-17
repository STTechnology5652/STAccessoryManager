//
//  STAccesorySessionInterface.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

/// 操作设备的接口
@objc public protocol STAccesoryHandlerInterface: NSObjectProtocol {
    @discardableResult func openSteam(_ open: Bool, protocol: String?) async -> STAccessoryWorkResult
    @discardableResult func sendCommand(_ data:Data, protocol: String?) -> STAccessoryWorkResult
}
