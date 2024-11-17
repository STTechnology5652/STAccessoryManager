//
//  STAccesoryHandler.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

import ExternalAccessory

class STAccesoryHandler: NSObject {
    let devSerinalNumber: String
    
    private var sessionMap = [String: STAccesorySession]()
    
    init(devSerinalNumber: String) {
        self.devSerinalNumber = devSerinalNumber
    }
}

//MARK: - 对外接口
extension STAccesoryHandler: STAccesoryHandlerInterface {
    @objc func sendCommand(_ data: Data, protocol proStr: String?) -> STAccessoryWorkResult {
        let result = Task{
            let sesionInfo = await getDevSession(proStr: proStr)
            guard sesionInfo.status.status == true, let session: STAccesorySession = sesionInfo.sesion else {
                return sesionInfo.status
            }
            await session.setData(data)
            return STAccessoryWorkResult()
        }
        
        return STAccessoryWorkResult()
    }
    
    func openSteam(_ open: Bool, protocol proStr: String?) async -> STAccessoryWorkResult {
        let sesionInfo = await getDevSession(proStr: proStr)
        guard sesionInfo.status.status == true, let session: STAccesorySession = sesionInfo.sesion else {
            return sesionInfo.status
        }
        
        return STAccessoryWorkResult()
    }
}

//MARK: - 内部方法
extension STAccesoryHandler: EAAccessoryDelegate {
    private func getDevSession(proStr: String?) async -> (status: STAccessoryWorkResult, sesion: STAccesorySession?) {
        guard let dev = STAccessoryManager.share().device(devSerinalNumber) else {
            let des = "设备已经断开连接"
            STLog.err(des)
            return (STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des), nil)
        }
        
        dev.delegate = self
        
        guard dev.isConnected == true else {
            let des = "设备已经断开连接"
            STLog.err(des)
            return (STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des), nil)
        }
        
        let sessionProtocol = proStr ?? dev.protocolStrings.first
        guard let sessionProtocol else {
            let des = "设备协议为空"
            STLog.err(des)
            return (STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des),nil)
        }
        
        if let session = sessionMap[sessionProtocol] {
            return (STAccessoryWorkResult(),session)
        } else {
            STLog.debug("start create STAccesorySession")
            let session = STAccesorySession(dev: dev, sessionProtocol: sessionProtocol)
            STLog.debug("finish create STAccesorySession")
            sessionMap[sessionProtocol] = session
            return (STAccessoryWorkResult(),session)
        }
    }
    
    private func deviceDisconnected(dev: EAAccessory) {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            let dict = sessionMap
            sessionMap.removeAll()
            for (k, v) in dict {
                v.deviceDisConnected()
            }
        }
    }
}

extension STAccesoryHandler: STAccessoryConnectDelegate {
    func didDisconnect(device: EAAccessory) {
        if device.serialNumber == devSerinalNumber { // 当前设备断开
            deviceDisconnected(dev: device)
        }
    }
}
