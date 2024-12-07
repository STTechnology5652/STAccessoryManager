//
//  STAccesoryHandlerInterface.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

public class STAccesoryCmdData {
   public let tag: UInt8
   public let data: Data
    
    public init(tag: UInt8, data: Data) {
        self.tag = tag
        self.data = data
    }
}

@objc
public protocol STAccesoryHandlerImageReceiver: NSObjectProtocol {
    func didReceiveDeviceImageResponse(_ imgRes: STAResponse)
}

public typealias STAComplete<T> = ((_:STAccessoryWorkResult<T>?)->Void)

/// 操作设备的接口
public protocol STAccesoryHandlerInterface: NSObjectProtocol {
    func getNextCmdTag() -> UInt8
    @discardableResult func openSteam(_ open: Bool, protocol: String?, complete: STAComplete<STAResponse>?)
    @discardableResult func sendCommand(_ cmdData:STAccesoryCmdData, protocol: String?, complete: STAComplete<STAResponse>?)
    @discardableResult func configImage(receiver: STAccesoryHandlerImageReceiver, protocol: String?, complete: STAComplete<String>?)
}

internal protocol STAccesoryHandlerInterface_pri: STAccesoryHandlerInterface {
    func deviceDisconnected(dev: EAAccessory)
}
