//
//  STASendStream.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/17.
//

import Foundation

private let kTag_STStream_send = "kTag_STStream_send"

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
    
    func sendData(_ data: Data) -> (success: Bool, des: String) {
        STLog.debug(tag: kTag_STStream_send, "add task, [total:\(data as NSData)]")
        
        let sem = DispatchSemaphore(value: 0)
        var result: (success: Bool, des: String) = (false, "time out")
        sendDataExe(data) { success, des in
            result = (success, des)
            sem.signal()
        }
        
        sem.wait(timeout: DispatchTime.now() + 2)
        return result
    }
    
    private func sendDataExe(_ data: Data, complete: @escaping ((_ success: Bool, _ des: String)->Void)) {
        let para = STASendParamater(data: data, callBack: complete)
        startSend(para)
    }
    
    private func startSend(_ para: STASendParamater? = nil) {
        sendQueue.async { [weak self] in
            guard let self else {
                STLog.err(tag: kTag_STStream_send, "send stream has been release")
                return
            }
            if let para {
                sendParamaterArr.append(para)
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
                    STLog.debug(tag: kTag_STStream_send, "send data start, [id:\(newPara.paramaterId)][total:\(newPara.dataTotal)]")
                }
                startSendExe(retryTime: 0)
            } else {
                //所有数据包发送完毕
                STLog.info(tag: kTag_STStream_send, "no data to be send, stream not in use")
            }
            return
        }
        
        guard curPara.dataToSend.count > 0 else { //当前数据包发送完毕， 需要回调任务完成
            STLog.debug(tag: kTag_STStream_send, "send data finish, [id:\(curPara.paramaterId)][bytes:\(curPara.dataTotal as NSData)]")
            STLog.info(tag: kTag_STStream_send, "send data finish, [id:\(curPara.paramaterId)][total:\(curPara.totalLen)]")
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
            STLog.warning(tag: kTag_STStream_send, "out put stream has no available space, should wait")
            return
        }
        
        let dataToSend = curPara.dataToSend // 待发送的数据包， 数据长度在此处一定不为空
        
        guard let bufferPointer:UnsafePointer<UInt8> = dataToSend.withUnsafeBytes { (rawBufferPointer: UnsafeRawBufferPointer) -> UnsafePointer<UInt8>? in
            return rawBufferPointer.baseAddress?.assumingMemoryBound(to: UInt8.self) // 将 UnsafeRawBufferPointer 转换为 UnsafePointer<UInt8>
        } as? UnsafePointer<UInt8> else {
            STLog.warning(tag: kTag_STStream_send, "write data failed, since read data byte failed, try one more")
            startSendExe(retryTime: retryTime + 1) //再尝试一次
            return
        }
        
        let writedCount = stream.write(bufferPointer, maxLength: dataToSend.count)
        if let err = stream.streamError { //写入失败
            STLog.warning(tag: kTag_STStream_send, "write data failed, and retry 3 times, error: \(err) ")
            startSendExe(retryTime: retryTime + 1)
            return
        }
        
        if writedCount <= 0 { //没有写入失败， 但是也没有发送出去数据， 重新尝试， 会尝试 3 次
            STLog.debug(tag: kTag_STStream_send, "send data less than 1, should retry: \(retryTime + 1) ")
            startSendExe(retryTime: retryTime + 1)
            return
        }
        
        let dataSuccess: Data = curPara.deleteSuccessBytes(writedCount) //删除已经发送成功的数据
        STLog.debug(tag: kTag_STStream_send, "send data succees[\(curPara.paramaterId)]: \(dataSuccess as NSData)")
        startSendExe(retryTime: 0) // 继续发送数据
    }
}

extension STASendStream: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        STLog.info(tag: kTag_STStream_send, "outPutStatus: \(eventCode.rawValue)")
        switch eventCode {
        case .openCompleted:
            STLog.debug(tag: kTag_STStream_send, "openCompleted")
        case .hasSpaceAvailable:
            STLog.debug(tag: kTag_STStream_send, "hasSpaceAvailable, start send buffer data")
            startSend()
        case .endEncountered:
            STLog.debug(tag: kTag_STStream_send, "endEncountered")
        case .errorOccurred:
            STLog.err(tag: kTag_STStream_send, "errorOccurred")
        default:
            STLog.err(tag: kTag_STStream_send, "un deal status")
        }
    }
}
