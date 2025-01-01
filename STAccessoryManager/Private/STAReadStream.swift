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
    
    // 读取回调队列
    let readCallBackQueue: DispatchQueue = {
        let uuidStr = UUID().uuidString
        return DispatchQueue(label: "com.stream.stMfi.read_\(uuidStr)", qos: .userInitiated)
    }()
    
    // 读取缓冲区
    private let readBufferSize = 1024 * 1024  // 512KB
    private let readBuffer: UnsafeMutablePointer<UInt8>
    
    init(stream: InputStream, delegate: STAReaderStreamDelegate) {
        self.stream = stream
        self.delegate = delegate
        self.readBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: readBufferSize)
        super.init()
        stream.delegate = self
        setupStream()
    }
    
    deinit {
        readBuffer.deallocate()
        closeStream()
    }
    
    private func setupStream() {
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
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
    
    private func readDataExe() {
        guard self.stream.hasBytesAvailable else {
            STLog.info(tag: kTag_STAReadStream, "stream has no bytes, wait reading")
            return
        }
        
        // 在当前线程直接读取，避免线程切换开销
        autoreleasepool {
            let bytesRead = self.stream.read(self.readBuffer, maxLength: self.readBufferSize)
            
            if bytesRead > 0 {
                // 使用 bytesNoCopy 避免内存复制
                let data = Data(bytesNoCopy: self.readBuffer,
                              count: bytesRead,
                              deallocator: .none)
                
                STLog.info(tag: kTag_STAReadStream, "read stream get byte <<<<< : \(bytesRead) bytes")
                
                // 异步通知代理
                self.readCallBackQueue.async {
                    self.delegate?.didReadData(data: data)
                }
                
                // 如果还有数据，继续读取
                if self.stream.hasBytesAvailable {
                    self.readDataExe()
                }
            } else if bytesRead < 0 {
                if let error = self.stream.streamError {
                    STLog.err(tag: kTag_STAReadStream, "Read error: \(error)")
                    self.handleStreamError(error)
                }
            }
        }
    }
    
    private func handleStreamError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 发送重连通知
            NotificationCenter.default.post(name: .streamNeedsReconnection, object: self)
            // 尝试重连
            self.reconnectStream()
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
            readDataExe()
        case .endEncountered:
            STLog.info(tag: kTag_STAReadStream, "endEncountered")
            reconnectStream()
        case .errorOccurred:
            STLog.info(tag: kTag_STAReadStream, "errorOccurred")
            if let error = aStream.streamError {
                handleStreamError(error)
            }
        default:
            STLog.err(tag: kTag_STAReadStream, "un deal status")
        }
    }
}

extension Notification.Name {
    static let streamNeedsReconnection = Notification.Name("streamNeedsReconnection")
}
