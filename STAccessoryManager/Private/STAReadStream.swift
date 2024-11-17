//
//  STAReadStream.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/17.
//

import Foundation

let maxReadBufferSize = 1024 * 1024 // 1M

protocol STAReaderStreamDelegate: NSObject {
    func didReadData(data: Data)
}

class STAReadStream: NSObject {
    private weak var delegate: STAReaderStreamDelegate?

    private var streamRunloop: RunLoop?
    let stream: InputStream
    let readQueue: DispatchQueue = {
        let uuidStr = UUID().uuidString
        let queue = DispatchQueue(label: "com.stream.stMfi.read_\(uuidStr)", qos: .default)
        return queue
    }()
    
    private var buffer: Data = Data()
    
    deinit {
        STLog.info()
        stream.close()
        if let streamRunloop {
            stream.remove(from: streamRunloop, forMode: .common)
        }
    }
    
    init(stream: InputStream, delegate: STAReaderStreamDelegate) {
        self.stream = stream
        self.delegate = delegate
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
    
    private func readData() {
        if stream.hasBytesAvailable {
            readQueue.async { [weak self] in
                guard let self else {
                    STLog.warning("read stream has ben relase")
                    return
                }
                readDataExe(retryCount: 0)
            }
        }
    }
    
    // 必须是串行队列调用， 防止资源竞争
    private func readDataExe(retryCount: Int) {
        if stream.hasBytesAvailable == false {
            STLog.info("stream has no bytes, wait reading")
            return
        }
        
        if retryCount > 4 { // 重试超过 4 次， 业务失败
            STLog.err("read stream retry one mor time: \(retryCount)")
            return
        }
        
        var byts = [UInt8](repeating: 0, count: maxReadBufferSize)  // 1KB buffer
        let bytesRead = stream.read(&byts, maxLength: byts.count)
        if let err = stream.streamError { //读取错误， 尝试 3 次
            STLog.err("read stream error: \(err)")
            readDataExe(retryCount: retryCount + 1)
            return
        }
        
        if bytesRead > 0 { // 读取到字节
            let dataRead = Data(byts.prefix(bytesRead))
            buffer.append(dataRead)
            STLog.debug(kTag_STStream, "read stream get bytes: \(buffer as NSData)")
            STLog.info(kTag_STStream, "read stream get byte: \(buffer)")
            
            if let delegate {
                let dataBack  = buffer
                buffer.removeAll()
                DispatchQueue.global().async {
                    delegate.didReadData(data: dataBack)
                }
            }
        } else { // 没有读取到字节，尝试再次读取
            STLog.warning("read stream get empty bytes, retry reading")
            readDataExe(retryCount: retryCount + 1)
            return
        }
    }
}

extension STAReadStream: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        STLog.info("intPutStatus:\(eventCode.rawValue)")
        switch eventCode {
        case .openCompleted:
            STLog.info("openCompleted")
        case .hasBytesAvailable:
            STLog.info("hasBytesAvailable")
            readData()
        case .endEncountered:
            STLog.info("endEncountered")
        case .errorOccurred:
            STLog.info("errorOccurred")
        default:
            STLog.err("un deal status")
        }
    }
}
