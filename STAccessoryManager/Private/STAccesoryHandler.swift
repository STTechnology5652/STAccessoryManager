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
    
    func configImage(receiver: STAccesoryHandlerImageReceiver, protocol proStr: String?, complete: STAComplete<String>?) {
        getDevSession(proStr: proStr) { [weak self] (sessionInfo:STAccessoryWorkResult<STAccesorySession>?) in
            guard let sessionInfo, sessionInfo.status == true, let session: STAccesorySession = sessionInfo.workData, let self else {
                complete?(STAccessoryWorkResult<String>(status: false, devSerialNumber: self?.devSerinalNumber ?? "", workDes: sessionInfo?.workDes ?? ""))
                return
            }
            
            session.configImageReceive(receiver)
            complete?(STAccessoryWorkResult(devSerialNumber: devSerinalNumber, workDes: sessionInfo.workDes, workData: "config session delegate success"))
            return
        }
    }
    
    func sendCommand(_ cmdData: STAccesoryCmdData, protocol proStr: String?, complete: STAComplete<STAResponse>?) {
        getDevSession(proStr: proStr) { [weak self] (sesionInfo:STAccessoryWorkResult<STAccesorySession>?) in
            guard let sesionInfo, sesionInfo.status == true, let session: STAccesorySession = sesionInfo.workData else {
                complete?(STAccessoryWorkResult<STAResponse>(status: false, devSerialNumber: self?.devSerinalNumber ?? "", workDes: sesionInfo?.workDes ?? ""))
                return
            }
            
            session.sendData(cmdData.data, cmdTag: cmdData.tag) { [weak self] (result:STAccessoryWorkResult<STAResponse>?) in
                complete?(result)
            }
        }
    }
    
    func openSteam(_ open: Bool, protocol proStr: String?, complete: STAComplete<STAResponse>?) {
        
        getDevSession(proStr: proStr) { [weak self] (sesionInfo:STAccessoryWorkResult<STAccesorySession>?) in
            guard let self, let sesionInfo, sesionInfo.status == true, let session: STAccesorySession = sesionInfo.workData else {
                complete?(STAccessoryWorkResult<STAResponse>(status: false, devSerialNumber: self?.devSerinalNumber ?? "", workDes: sesionInfo?.workDes ?? ""))
                return
            }

            let cmdTag = cmdTag.getNextCmdTag()
            let cmdData: Data = STACommandserialization.openStreamCmd(withTag: cmdTag, open: open ? 0x01 : 0x00)
            
            let command = STAccesoryCmdData(tag: cmdTag, data: cmdData)
            sendCommand(command, protocol: proStr, complete: complete)
        }
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
    private func getDevSession(proStr: String?, complete: STAComplete<STAccesorySession>?) {
        guard let dev = STAccessoryManager.share().device(devSerinalNumber) else {
            let des = "设备已经断开连接"
            STLog.err(des)
            complete?(STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des, workData: nil))
            return
        }
        
        dev.delegate = self
        
        guard dev.isConnected == true else {
            let des = "设备已经断开连接"
            STLog.err(des)
            complete?(STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des))
            return
        }
        
        let sessionProtocol = proStr ?? dev.protocolStrings.first
        guard let sessionProtocol else {
            let des = "设备协议为空"
            STLog.err(des)
            complete?(STAccessoryWorkResult(status: false, devSerialNumber: devSerinalNumber, workDes: des))
            return
        }
        
        if let session = sessionMap[sessionProtocol] {
            complete?(STAccessoryWorkResult(devSerialNumber: devSerinalNumber, workData: session))
            return
        } else {
            STLog.debug("start create STAccesorySession")
            
            let responseSer = STAResponseSeriaLizer(devSerial: devSerinalNumber, protocolIdv: sessionProtocol)
            let session = STAccesorySession(dev: dev, sessionProtocol: sessionProtocol, responseSerializer: responseSer)
            STLog.debug("finish create STAccesorySession")
            sessionMap[sessionProtocol] = session
            complete?(STAccessoryWorkResult(devSerialNumber: devSerinalNumber, workData: session))
            return
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
