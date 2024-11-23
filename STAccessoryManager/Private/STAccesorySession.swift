//
//  STAccesorySession.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/16.
//

import ExternalAccessory
import Darwin
import STLog

private class CommandToSendQueue {
    private class STADataToDeviceModel: Equatable {
        static func == (lhs: CommandToSendQueue.STADataToDeviceModel, rhs: CommandToSendQueue.STADataToDeviceModel) -> Bool {
            lhs.idv == rhs.idv
        }
        
        private let idv = UUID().uuidString
        let cmdTag: UInt8
        let data: Data
        private(set) var callBack: ((_ response: STAResponse)->Void)?
        init(data: Data, cmdTag: UInt8, callBack: ((_: STAResponse) -> Void)?) {
            self.cmdTag = cmdTag
            self.data = data
            self.callBack = callBack
        }
        
        func removeCallBack() {
            callBack = nil
        }
    }
    
    private var rwLock = pthread_rwlock_t()
    private var dataArr = [STADataToDeviceModel]()
    
    deinit {
        cancelAll()
    }
    
    init() {
        pthread_rwlock_init(&rwLock, nil)
    }
    
    func appendCmdData(cmdTag: UInt8, data: Data, callBack:@escaping ((_: STAResponse) -> Void)) {
        pthread_rwlock_wrlock(&rwLock)
        let cmd = STADataToDeviceModel(data: data, cmdTag: cmdTag, callBack: callBack)
        dataArr.append(cmd)
        pthread_rwlock_unlock(&rwLock)
    }
    
    func deleteCmd(tag: UInt8) -> ((_: STAResponse) -> Void)? {
        pthread_rwlock_wrlock(&rwLock)
        let cmd = dataArr.filter{$0.cmdTag == tag}.first
        let result = cmd?.callBack
        dataArr.removeAll{$0 == cmd}
        pthread_rwlock_unlock(&rwLock)
        return result
    }
    
    func cancelAll() {
        pthread_rwlock_wrlock(&rwLock)
        let arr = dataArr
        dataArr.removeAll()
        pthread_rwlock_unlock(&rwLock)
        arr.forEach { one in //回调任务失败， 其实就是任务取消了
            one.callBack?(STAResponse())
        }
    }
}


private let kTag_STAccesorySession = "kTag_STAccesorySession"
class STAccesorySession: NSObject{
    let dev: EAAccessory
    let sessionProtocol: String
    
    private let commandQueue =  CommandToSendQueue()
    
    private let session: EASession?
    private var sender: STASendStream?
    private var reader: STAReadStream?
    private let responseSerializer: STAResponseSeriaLizerProtocol
    // 解析指令的线程
    private let analysisQueue = {
        let queueId = UUID().uuidString
        let queue = DispatchQueue(label: "STAccesorySession_\(queueId)")
        return queue
    }()
    
    private var imageReceiverArr: NSPointerArray = NSPointerArray.weakObjects()

    deinit {
        commandQueue.cancelAll()
    }
    
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
            STLog.err(tag: kTag_STAccesorySession, "not create EASession")
        }
    }
    
    func deviceDisConnected() { //设备断开后，需要停止流，并将流从runloop中移除
        sender = nil
        reader = nil
        commandQueue.cancelAll()
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
        let allData = data
        analysisQueue.async {
            autoreleasepool { [weak self] in
                guard let self else {
                    STLog.err(tag: kTag_STAccesorySession, "analysis device data work failed, since no session")
                    return
                }
                let cmdAnalysisResult: (resArr:[STAResponse], usedByts: UInt64) = responseSerializer.shouldAnalysisBuffer(buffer: data)
                STLog.err(tag: kTag_STAccesorySession, "anasysis device data success, total success: \(cmdAnalysisResult.usedByts)")
                
                cmdAnalysisResult.resArr.forEach { (cmdRes: STAResponse) in
                    switch cmdRes.analysisStatus {
                    case .failed:
                        STLog.err(tag: kTag_STAccesorySession, "workfailed, should delete anasysised data and wait one mor data: \(cmdRes.usedLength)")
                        analysisDevDataSuccess(response: cmdRes)
                    case .dataNotEnough:
                        STLog.warning(tag: kTag_STAccesorySession, "data not enough and wait one more data")
                    case .success:
                        STLog.info(tag: kTag_STAccesorySession, "analysis success and wait one more data，analysisLen[\(cmdRes.usedLength)]")
                        analysisDevDataSuccess(response: cmdRes)
                    @unknown default:
                        STLog.warning(tag: kTag_STAccesorySession, "data analysis not know result, delete all data and wait one more data")
                    }
                }
            }
        }
    }
    
    private func analysisDevDataSuccess(response: STAResponse) {
        let callBack = commandQueue.deleteCmd(tag: response.resHeader.cmdTag)
        DispatchQueue.global().async { [weak self] in
            callBack?(response)
            if response.imageData.count > 0 { //收到图像的回调
                if let self {
                    var receiversArr: [STAccesoryHandlerImageReceiver] = self.imageReceiverArr.allObjects.flatMap { one in
                        return one as? STAccesoryHandlerImageReceiver
                    }
                    
                    receiversArr.forEach { oneReceivew in
                        oneReceivew.didReceiveDeviceImageResponse(response)
                    }
                }
            }
        }
    }
}

//MARK: - reader delegate
extension STAccesorySession: STAReaderStreamDelegate {
    func didReadData(data: Data) {
        analysisDevUploadData(data)
    }
}

//MARK: - 业务接口
extension STAccesorySession {
    
    func configImageReceive(_ receiver: STAccesoryHandlerImageReceiver) {
        imageReceiverArr.pointerFunctions
        imageReceiverArr.addPointer(Unmanaged.passUnretained(receiver).toOpaque())
    }
    
    func sendData(_ data: Data, cmdTag: UInt8 = 0x08) async -> STAResponse? {
        guard let sender else {
            STLog.err(tag: kTag_STAccesorySession, "no sender")
            return nil
        }
        
        return await withCheckedContinuation { continuation in // block 回调 转为协程回调
            sendDataExe(data, cmdTag: cmdTag) { resp in
                return continuation.resume(returning: resp)
            }
        }
    }
    
    private func sendDataExe(_ data: Data, cmdTag: UInt8, complete: @escaping ((_ resp: STAResponse) -> Void)) {
        commandQueue.appendCmdData(cmdTag: cmdTag, data: data, callBack: complete)
        Task {
            await sender?.sendData(data)
        }
    }
}
