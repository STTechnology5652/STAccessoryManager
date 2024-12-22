//
//  STAResponseSerializer.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

import Foundation

private let kMaxPackageSize: UInt64 = 1024 * 1024 * 2

class STAResponseSeriaLizer: NSObject, STAResponseSeriaLizerProtocol {
    let devSerial: String
    let protocolIdv: String
    let analysisQueue = DispatchQueue(label: "STAResponseSerialLizerWorkQueue")
    let delegateQueue = DispatchQueue(label: "STAResponseSerialLizerBackQueue")
    weak var delegate: (NSObject & STASerialResultDelegate)?
    
    private var isWorking = false
    init(devSerial: String, protocolIdv: String) {
        self.devSerial = devSerial
        self.protocolIdv = protocolIdv
    }
    
    private var bufferStore = [Data]()
    private var bufferTotalBytes: UInt64 = 0
    
    deinit {
        bufferStore.removeAll()
    }
    
    func shouldAnalysisBuffer(buffer: Data) {
        analysisQueue.async { [weak self] in
            guard let self else { return }
            bufferStore.append(buffer)
            bufferTotalBytes += UInt64(buffer.count)
            startAnalysisData()
        }
    }
    
    private func startAnalysisData() {
        // 递归解包
        if isWorking == false, let one = bufferStore.first {
            bufferStore.removeFirst()
            bufferTotalBytes -= UInt64(one.count)
            if bufferTotalBytes > kMaxPackageSize { //数据累计过多， 开始丢弃累积的数据
                bufferStore.removeAll()
                bufferTotalBytes = 0
            }
            analysisDataExe(onePackage: one)
        } else { //已经在递归解包， 不需要重新开始任务
            
        }
    }
    
    private func analysisDataExe(onePackage one: Data) {
        isWorking = true
        STLog.debug("start analysis data: \(one.count)")
        var usedLength: UInt64 = 0
        var secondsUsed: TimeInterval = 0
        let responseArr: [STAResponse] = STAResponse.analysisiBuffer(one, byteUsed: &usedLength, timeUsed: &secondsUsed)
        backDevData(responseArr)
        isWorking = false
        startAnalysisData() // 递归解析协议包
    }
    
    private func backDevData(_ arr: [STAResponse]) {
        if let delegate {
            delegateQueue.async {
                delegate.didAnalysisOnePackage(resArr: arr)
            }
        }
    }
}
