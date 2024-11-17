//
//  STAccesorySession.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

import ExternalAccessory

class STAccesorySession: NSObject{
    let dev: EAAccessory
    let sessionProtocol: String
    
    private let session: EASession?
    private var sender: STASendStream?
    private var reader: STAReadStream?
    
    init(dev: EAAccessory, sessionProtocol: String) {
        STLog.info()
        self.dev = dev
        self.sessionProtocol = sessionProtocol
        session = EASession(accessory: dev, forProtocol: sessionProtocol)
        super.init()
        
        if let session {
            configSession(session)
        } else {
            STLog.err("not create EASession")
        }
    }
    
    func deviceDisConnected() { //设备断开后，需要停止流，并将流从runloop中移除
        sender = nil
        reader = nil
    }
    
    @discardableResult func cancelWork() async -> STAccessoryWorkResult {
        STLog.info()
        return STAccessoryWorkResult()
    }
    
    private func configSession(_ session: EASession) {
        if let output = session.outputStream {
            let streamOut = STASendStream(stream: output)
           sender = streamOut
        }
        
        if let input = session.inputStream {
           let streamInput = STAReadStream(stream: input, delegate: self)
            reader = streamInput
        }
    }
}

//MARK: - reader delegate
extension STAccesorySession: STAReaderStreamDelegate {
    func didReadData(data: Data) {
        STLog.info("read get data: \(data)")
    }
}

//MARK: - 业务接口
extension STAccesorySession {
    func setData(_ data: Data) async {
        guard let sender else {
            STLog.err("no sender")
            return
        }
        let result = await sender.sendData(data)
        STLog.info("send cmd result: \(result.des)")
    }
}
