//
//  STASendStream.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/17.
//

import Foundation

private class STASendParamater {
    let paramaterId = UUID().uuidString
    let callBack: STASendStream.SendCallBack
    let totalLen: Int
    let dataTotal: Data
    private(set) var dataToSend: Data
    
    init(data: Data, callBack: @escaping STASendStream.SendCallBack) {
        self.callBack = callBack
        self.dataTotal = data
        self.dataToSend = data
        self.totalLen = data.count
    }
    
    @discardableResult func deleteSuccessBytes(_ len: Int) -> Data {
        if len > dataToSend.count {
            let deleted = dataToSend
            dataToSend.removeAll()
            return deleted
        } else {
            let deleted = dataToSend.subdata(in: 0..<len)
            dataToSend = dataToSend.subdata(in: len..<dataToSend.count)
            return deleted
        }
    }
}

class STASendStream: NSObject {
    typealias SendCallBack = ((_ success: Bool, _ des: String)->Void)
    private var sendParamaterArr = [STASendParamater]()
    private var sendingPara: STASendParamater?
    
    private var streamRunloop: RunLoop?
    let stream: OutputStream
    let sendQueue: DispatchQueue = {
        let uuidStr = UUID().uuidString
        let queue = DispatchQueue(label: "com.stream.stMfi.send_\(uuidStr)", qos: .default)
        return queue
    }()

    deinit {
        STLog.info()
        stream.close()
        if let streamRunloop {
            stream.remove(from: streamRunloop, forMode: .common)
        }
    }
    
    init(stream: OutputStream) {
        self.stream = stream
        super.init()
        stream.delegate = self
        
        DispatchQueue.global().async { [weak self] in
            guard let self else {return}
            let runloop = RunLoop.current
            streamRunloop = runloop
            stream.schedule(in: runloop, forMode: .common)
            stream.open()
            runloop.run()  // 确保 RunLoop 持续运行
        }
    }
    
    func sendData(_ data: Data) async -> (success: Bool, des: String) {
        STLog.debug(kTag_STStream, "add task, [total:\(data as NSData)]")
        return await withCheckedContinuation { (continuation: CheckedContinuation<(Bool, String), Never>) in
            sendDataExe(data) { success, des in
                continuation.resume(returning: (success, des))
            }
        }
    }
    
    private func sendDataExe(_ data: Data, complete: @escaping ((_ success: Bool, _ des: String)->Void)) {
        let para = STASendParamater(data: data, callBack: complete)
        sendParamaterArr.append(para)
        startSend()
    }
    
    private func startSend() {
        sendQueue.async { [weak self] in
            guard let self else {
                STLog.err("send stream has been release")
                return
            }
            startSendExe(retryTime: 0)
        }
    }
    
    private func startSendExe(retryTime: Int) {
        guard let curPara = sendingPara else {
            //没有正在发送的数据包
            if sendParamaterArr.count > 0 {
                sendingPara = sendParamaterArr.first
                sendParamaterArr.removeFirst()
                // 递归调用，发送下一个数据包
                if let newPara = sendingPara {
                    STLog.debug(kTag_STStream, "send data start, [id:\(newPara.paramaterId)][total:\(newPara.dataTotal)]")
                }
                startSendExe(retryTime: 0)
            } else {
                //所有数据包发送完毕
                STLog.info("no data to be send, stream not in use")
            }
            return
        }
        
        guard curPara.dataToSend.count > 0 else { //当前数据包发送完毕， 需要回调任务完成
            STLog.debug(kTag_STStream, "send data finish, [id:\(curPara.paramaterId)][bytes:\(curPara.dataTotal as NSData)]")
            STLog.info(kTag_STStream, "send data finish, [id:\(curPara.paramaterId)][total:\(curPara.totalLen)]")
            sendingPara = nil
            let callBack = curPara.callBack
            let identifier = curPara.paramaterId
            DispatchQueue.global().async {
                callBack(true, "send success")
            }
            
            startSendExe(retryTime: 0) // 发送下一包
            return
        }
        
        if retryTime > 4 { //当前数据包发送失败， 需要开始下一个数据包的发送， 直到所有数据包都发送失败
            let callBack = sendingPara?.callBack
            sendParamaterArr.removeFirst()
            sendingPara = sendParamaterArr.first
            
            DispatchQueue.global().async {
                callBack?(false, "send data failed")
            }
            
            // 递归调用，发送下一个数据包
            startSendExe(retryTime: 0)
            return
        }

        guard stream.hasSpaceAvailable else {
            STLog.warning("out put stream has no available space, should wait")
            return
        }
        
        let dataToSend = curPara.dataToSend // 待发送的数据包， 数据长度在此处一定不为空
        
        guard let bufferPointer:UnsafePointer<UInt8> = dataToSend.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) -> UnsafePointer<UInt8>? in
            return rawBufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self) // 将 UnsafeRawBufferPointer 转换为 UnsafePointer<UInt8>
        } as? UnsafePointer<UInt8> else {
            STLog.warning("write data failed, since read data byte failed, try one more")
            startSendExe(retryTime: retryTime + 1) //再尝试一次
            return
        }
        
        let writedCount = stream.write(bufferPointer, maxLength: dataToSend.count)
        if let err = stream.streamError { //写入失败
            STLog.warning("write data failed, and retry 3 times, error: \(err) ")
            startSendExe(retryTime: retryTime + 1)
            return
        }
        
        if writedCount <= 0 { //没有写入失败， 但是也没有发送出去数据， 重新尝试， 会尝试 3 次
            STLog.debug("send data less than 1, should retry: \(retryTime + 1) ")
            startSendExe(retryTime: retryTime + 1)
            return
        }
        
        let dataSuccess: Data = curPara.deleteSuccessBytes(writedCount) //删除已经发送成功的数据
        STLog.debug(kTag_STStream, "write bytes succees[\(curPara.paramaterId)]: \(dataSuccess as NSData)")
        startSendExe(retryTime: 0) // 继续发送数据
    }
}

extension STASendStream: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        STLog.info("outPutStatus: \(eventCode.rawValue)")
        switch eventCode {
        case .openCompleted:
            STLog.debug("openCompleted")
        case .hasSpaceAvailable:
            STLog.debug("hasSpaceAvailable, start send buffer data")
            startSend()
        case .endEncountered:
            STLog.debug("endEncountered")
        case .errorOccurred:
            STLog.err("errorOccurred")
        default:
            STLog.err("un deal status")
        }
    }
}
