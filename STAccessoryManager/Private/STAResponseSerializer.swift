//
//  STAResponseSerializer.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

import Foundation

private let kMaxPackageSize: UInt64 = 1024 * 1024
private let kMaxConcurentAnalysisCount: Int = 8
private let kMaxPackageStoreCount: UInt64 = 512
private let kCleanupThreshold: UInt64 = 500
private let kMaxPendingResults: Int = 1000 // 最大待处理结果数

private class STASerialWork {
    let data: Data
    let workSerialNum: UInt64
    init(data: Data, workSerialNum: UInt64) {
        self.data = data
        self.workSerialNum = workSerialNum
    }
}

private class STASerilaResultToBack {
    let resultArr: [STAResponse]
    let serialNum: UInt64
    
    init(resultArr: [STAResponse], serialNum: UInt64) {
        self.resultArr = resultArr
        self.serialNum = serialNum
    }
}

class STAResponseSeriaLizer: NSObject, STAResponseSeriaLizerProtocol {
    weak var delegate: (any NSObject & STASerialResultDelegate)?
    
    // 1. 使用串行队列避免竞争条件
    private let processingQueue = DispatchQueue(label: "com.sta.serializer.processing",
                                              qos: .userInitiated)
    private let callbackQueue = DispatchQueue.main
    
    // 2. 使用批处理来提高效率
    private var pendingData = Data()
    private let batchSize = 64 * 1024 // 64KB batch size
    private let maxPendingSize = 1024 * 1024 // 1MB max pending
    
    // 3. 使用信号量控制并发
    private let semaphore = DispatchSemaphore(value: 3)
    
    // 4. 跟踪处理状态
    private var currentSerialNum: UInt64 = 0
    private var pendingResults = [STASerilaResultToBack]()
    
    override init() {
        super.init()
    }
    
    func shouldAnalysisBuffer(buffer: Data) {
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 5. 添加流控制
            if self.pendingData.count > self.maxPendingSize {
                print("[Warning] Pending data exceeds limit, dropping data")
                return
            }
            
            // 6. 批处理数据
            self.pendingData.append(buffer)
            
            while self.pendingData.count >= self.batchSize {
                autoreleasepool {
                    // 7. 使用信号量控制并发
                    self.semaphore.wait()
                    
                    let batch = self.pendingData.prefix(self.batchSize)
                    self.pendingData.removeFirst(self.batchSize)
                    
                    // 8. 处理数据批次
                    self.processBatch(Data(batch)) { [weak self] responses in
                        self?.deliverResponses(responses)
                        self?.semaphore.signal()
                    }
                }
            }
        }
    }
    
    private func processBatch(_ data: Data, completion: @escaping ([STAResponse]) -> Void) {
        autoreleasepool {
            let startTime = CFAbsoluteTimeGetCurrent()
            var usedLength: UInt64 = 0
            let responses = STAProtocolParserBridge.parseBuffer(data, bytesUsed: &usedLength)
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            STLog.info(tag: "Parser", "Parse stats: used \(usedLength)/\(data.count) bytes, \(responses.count) packets, time: \(duration)s")
            
            completion(responses)
        }
    }
    
    private func deliverResponses(_ responses: [STAResponse]) {
        guard !responses.isEmpty else { return }
        
        callbackQueue.async { [weak self] in
            self?.delegate?.didAnalysisOnePackage(resArr: responses)
        }
    }
}

// 8. 高效的环形缓冲区实现
private class RingBuffer {
    private var buffer: UnsafeMutableBufferPointer<UInt8>
    private var writeIndex = 0
    private var readIndex = 0
    private let capacity: Int
    
    init(capacity: Int) {
        self.capacity = capacity
        buffer = .allocate(capacity: capacity)
    }
    
    deinit {
        buffer.deallocate()
    }
    
    var availableBytes: Int {
        return writeIndex - readIndex
    }
    
    func write(_ data: Data) {
        data.withUnsafeBytes { ptr in
            let count = min(data.count, capacity - (writeIndex % capacity))
            memcpy(buffer.baseAddress?.advanced(by: writeIndex % capacity),
                  ptr.baseAddress!,
                  count)
            writeIndex += count
        }
    }
    
    func read(size: Int) -> Data? {
        guard availableBytes > 0,
              let baseAddress = buffer.baseAddress else { 
            return nil 
        }
        
        let count = min(size, availableBytes)
        let start = readIndex % capacity
        
        // 创建一个临时缓冲区来存储读取的数据
        let tempBuffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: count)
        defer { tempBuffer.deallocate() }
        
        // 复制数据到临时缓冲区
        memcpy(tempBuffer.baseAddress!,
               baseAddress.advanced(by: start),
               count)
        
        // 使用临时缓冲区创建 Data
        let data = Data(bytes: tempBuffer.baseAddress!, count: count)
        readIndex += count
        
        return data
    }
}
