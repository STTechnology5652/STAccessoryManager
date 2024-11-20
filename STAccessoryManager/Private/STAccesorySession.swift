//
//  STAccesorySession.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

import ExternalAccessory
import Darwin
import STLog

private class STAReaderBuffer {
    private var rwLock = pthread_rwlock_t()
    private var dataBuffer = Data()
    init() {
        pthread_rwlock_init(&rwLock, nil)
    }
    
    deinit {
        STLog.debug("should clear buffer")
        dataBuffer.removeAll()
    }
    
    func appendData(_ data: Data) {
        pthread_rwlock_wrlock(&rwLock)
        dataBuffer.append(data)
        pthread_rwlock_unlock(&rwLock)
    }
    
    func removeData(length: Int) {
        pthread_rwlock_wrlock(&rwLock)
        if length > dataBuffer.count {
            dataBuffer.removeAll()
        } else {
            autoreleasepool {
                let deleted = dataBuffer.subdata(in: 0..<length)
                dataBuffer = dataBuffer.subdata(in: length..<dataBuffer.count)
            }
        }
        pthread_rwlock_unlock(&rwLock)
    }
    
    func getAllData() -> Data {
        pthread_rwlock_rdlock(&rwLock)
        let result = dataBuffer
        pthread_rwlock_unlock(&rwLock)
        return result
    }
}

class STAccesorySession: NSObject{
    let dev: EAAccessory
    let sessionProtocol: String
    
    private let buffer = STAReaderBuffer()
    
    private let session: EASession?
    private var sender: STASendStream?
    private var reader: STAReadStream?
    private let responseSerializer: STAResponseSeriaLizerProtocol
    
    init(dev: EAAccessory, sessionProtocol: String, responseSerializer: STAResponseSeriaLizerProtocol) {
        STLog.info()
        self.dev = dev
        self.sessionProtocol = sessionProtocol
        self.responseSerializer = responseSerializer
        
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
        buffer.removeData(length: buffer.getAllData().count)
        STLog.debug("empty receive buffer size: \(buffer.getAllData().count)")
    }
    
    @discardableResult func cancelWork() async -> STAccessoryWorkResult<Any> {
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

//MARK: - analysis dev response
extension STAccesorySession {
    private func analysisDevUploadData(_ data: Data) {
        buffer.appendData(data)
        autoreleasepool {
            let allData = buffer.getAllData()
            let cmdRes: STACmdResponse = responseSerializer.shouldAnalysisBuffer(buffer: allData)
            if cmdRes.analysisSuccess { //解析到数据包
                buffer.removeData(length: cmdRes.usedLenght) //移除已经解析到的数据
            } else { // 由于可能存在分包的问题， 确实没有解析到数据
                STLog.warning("not analysis buffer for device upload data, wait one mor data")
            }
        }
    }
}

//MARK: - reader delegate
extension STAccesorySession: STAReaderStreamDelegate {
    func didReadData(data: Data) {
        STLog.info("read get data: \(data)")
        analysisDevUploadData(data)
    }
}

//MARK: - 业务接口
extension STAccesorySession {
    func sendData(_ data: Data) async {
        guard let sender else {
            STLog.err("no sender")
            return
        }
        let result = await sender.sendData(data)
        STLog.info("send cmd result: \(result.des)")
    }
}
