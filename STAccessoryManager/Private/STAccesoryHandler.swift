//
//  STAccesoryHandler.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

import ExternalAccessory

class STAccesoryHandler: NSObject {
    class CMDTag { //读写安全， 因为指令序号一定不能乱序了
        private var tag: UInt8 = 0x08
        private var rwLock = pthread_rwlock_t()
        init() {
            pthread_rwlock_init(&rwLock, nil)
        }
        func getNextCmdTag() -> UInt8 {
            pthread_rwlock_wrlock(&rwLock)
            let next = tag % 0x0F
            tag = next + 1
            pthread_rwlock_unlock(&rwLock)
            return next
        }
    }
    
    let devSerinalNumber: String
    
    private var cmdTag: CMDTag = CMDTag();
    private var sessionMap = [String: STAccesorySession]()
    
    init(devSerinalNumber: String) {
        self.devSerinalNumber = devSerinalNumber
    }
}

//MARK: - 对外接口
extension STAccesoryHandler: STAccesoryHandlerInterface_pri {
    func getNextCmdTag() -> UInt8 {
        return cmdTag.getNextCmdTag()
    }

    func sendCommand(_ cmgData: STAccesoryCmdData, protocol proStr: String?) -> STAccessoryWorkResult<Any> {
        let result = Task{
            let sesionInfo = await getDevSession(proStr: proStr)
            guard sesionInfo.status == true, let session: STAccesorySession = sesionInfo.workData else {
                return STAccessoryWorkResult<Any>(status: false, devSerialNumber: devSerinalNumber, workDes: sesionInfo.workDes)
            }
            await session.sendData(cmgData.data)
            return STAccessoryWorkResult()
        }
        
        return STAccessoryWorkResult()
    }
    
    func openSteam(_ open: Bool, protocol proStr: String?) async -> STAccessoryWorkResult<Any> {
        let sesionInfo = await getDevSession(proStr: proStr)
        let cmdTag = cmdTag.getNextCmdTag()
        let cmdData: Data = STACommandserialization.openStreamCmd(withTag: cmdTag, open: open ? 0x01 : 0x00)
        
        let command = STAccesoryCmdData(tag: cmdTag, data: cmdData)
        let openResult = sendCommand(command, protocol: proStr)
        return openResult
    }
    
    func deviceDisconnected(dev: EAAccessory) {
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

//MARK: - 内部方法
extension STAccesoryHandler: EAAccessoryDelegate {
    private func getDevSession(proStr: String?) async -> STAccessoryWorkResult<STAccesorySession> {
        guard let dev = STAccessoryManager.share().device(devSerinalNumber) else {
            let des = "设备已经断开连接"
            STLog.err(des)
            return STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des, workData: nil)
        }
        
        dev.delegate = self
        
        guard dev.isConnected == true else {
            let des = "设备已经断开连接"
            STLog.err(des)
            return STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des)
        }
        
        let sessionProtocol = proStr ?? dev.protocolStrings.first
        guard let sessionProtocol else {
            let des = "设备协议为空"
            STLog.err(des)
            return STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des)
        }
        
        if let session = sessionMap[sessionProtocol] {
            return STAccessoryWorkResult(devSerialNumber: devSerinalNumber, workData: session)
        } else {
            STLog.debug("start create STAccesorySession")
            
            let responseSer = STAResponseSeriaLizer(devSerial: devSerinalNumber, protocolIdv: sessionProtocol)
            let session = STAccesorySession(dev: dev, sessionProtocol: sessionProtocol, responseSerializer: responseSer)
            STLog.debug("finish create STAccesorySession")
            sessionMap[sessionProtocol] = session
            return STAccessoryWorkResult(devSerialNumber: devSerinalNumber, workData: session)
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
