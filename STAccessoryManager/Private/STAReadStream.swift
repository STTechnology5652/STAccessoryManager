//
//  STAReadStream.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/17.
//

import Foundation

let maxReadBufferSize =  1024 * 512 // 1M

protocol STAReaderStreamDelegate: NSObject {
    func didReadData(data: Data)
}

private let kTag_STAReadStream = "kTag_STAReadStream"
class STAReadStream: NSObject {
    private weak var delegate: STAReaderStreamDelegate?

    private var streamRunloop: RunLoop?
    let stream: InputStream
    let readCallBackQueue: DispatchQueue = {
        let uuidStr = UUID().uuidString
        let queue = DispatchQueue(label: "com.stream.stMfi.read_\(uuidStr)", qos: .default)
        return queue
    }()
    
    deinit {
        STLog.info()
        closeStream()
    }
    
    init(stream: InputStream, delegate: STAReaderStreamDelegate) {
        self.stream = stream
        self.delegate = delegate
        super.init()
        stream.delegate = self
        setupStream()
    }
    
    private func setupStream() {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            let runloop = RunLoop.current
            self.streamRunloop = runloop
            self.stream.schedule(in: runloop, forMode: .common)
            self.stream.open()
            runloop.run()
        }
    }
    
    private func closeStream() {
        stream.close()
        if let streamRunloop {
            stream.remove(from: streamRunloop, forMode: .common)
        }
    }
    
    private func reconnectStream() {
        closeStream()
        setupStream()
    }
    
    private func readData() {
        readDataExe()
    }
    
    // 必须是串行队列调用， 防止资源竞争
    private func readDataExe() {
        if stream.hasBytesAvailable == false {
            STLog.info(tag: kTag_STAReadStream, "stream has no bytes, wait reading")
            return
        }
        
        autoreleasepool { [weak self] in
            var byts = [UInt8](repeating: 0, count: maxReadBufferSize)  // 1KB buffer
            let bytesRead = stream.read(&byts, maxLength: byts.count)
            if bytesRead > 0 { // 读取到字节
                let dataRead = Data(byts.prefix(bytesRead))
//                STLog.debug(tag: kTag_STAReadStream, justLogFile: true, "read stream get bytes [\(dataRead.count)]: \((dataRead as NSData).hexString())")
                STLog.info(tag: kTag_STAReadStream, "read stream get byte <<<<< : \(dataRead)")
                self?.delegate?.didReadData(data: dataRead)
                readData()
            }
            else { // 没有读取到字节，尝试再次读取
                STLog.warning(tag: kTag_STAReadStream, "read stream get empty bytes")
                return
            }
        }
    }
}

extension STAReadStream: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .openCompleted:
            STLog.info(tag: kTag_STAReadStream, "openCompleted")
        case .hasBytesAvailable:
            STLog.info(tag: kTag_STAReadStream, "hasBytesAvailable")
            readData()
        case .endEncountered:
            STLog.info(tag: kTag_STAReadStream, "endEncountered")
            // 流结束时自动重连
            reconnectStream()
        case .errorOccurred:
            STLog.info(tag: kTag_STAReadStream, "errorOccurred")
            // 发生错误时也尝试重连
            reconnectStream()
        default:
            STLog.err(tag: kTag_STAReadStream, "un deal status")
        }
    }
}

// 添加通知名称
extension Notification.Name {
    static let streamNeedsReconnection = Notification.Name("streamNeedsReconnection")
}
