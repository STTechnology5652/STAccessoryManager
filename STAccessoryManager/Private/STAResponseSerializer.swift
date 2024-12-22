//
//  STAResponseSerializer.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

import Foundation

private let kMaxPackageSize: UInt64 = 1024 * 512
private let kMaxConcurentAnalysisCount: Int = 8
private let kMaxPackageStoreCount: UInt64 = 512  //同时允许暂存 512 个包， 如果超过，就丢弃已经缓存的所有包

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
    let devSerial: String
    let protocolIdv: String
    let analysisQueue = DispatchQueue(label: "STAResponseSerialLizerWorkQueue")
    let delegateQueue = DispatchQueue(label: "STAResponseSerialLizerBackQueue")
    weak var delegate: (NSObject & STASerialResultDelegate)?
    
    private var analysisSerilaNumber: UInt64 = 0
    private var concurruntCount = kMaxConcurentAnalysisCount //任务并发数，同时允许n个解包任务
    
    init(devSerial: String, protocolIdv: String) {
        self.devSerial = devSerial
        self.protocolIdv = protocolIdv
    }
    
    private var bufferStore = [STASerialWork]()
    private var resultToBack = [STASerialWork]()
    
    private var bufferTotalBytes: UInt64 = 0
    
    deinit {
        bufferStore.removeAll()
    }
    
    func shouldAnalysisBuffer(buffer: Data) {
        analysisQueue.async { [weak self] in
            guard let self, buffer.count > 0 else { return }
            self.analysisSerilaNumber += 1
            let oneWork = STASerialWork(data: buffer, workSerialNum: self.analysisSerilaNumber)
            bufferStore.append(oneWork)
            bufferTotalBytes += UInt64(buffer.count)
            startAnalysisData()
        }
    }
    
    private func startAnalysisData() {
        // 递归解包
        if concurruntCount > 0, let one = bufferStore.first {
            bufferStore.removeFirst()
            bufferTotalBytes -= UInt64(one.data.count)
            analysisDataExe(onePackage: one)
        } else { //并发任务过多， 不需要开新任务
            if bufferTotalBytes > kMaxPackageSize, bufferStore.count > kMaxPackageStoreCount { //数据累计过多， 开始丢弃累积的数据
                STLog.info("Too more data to analysis, clear them")
                bufferStore.removeAll()
                bufferTotalBytes = 0
                concurruntCount = kMaxConcurentAnalysisCount
            }
        }
    }
    
    private func analysisDataExe(onePackage one: STASerialWork) {
        concurruntCount -= 1
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            STLog.debug("start analysis data: \(one.data.count)")
            var usedLength: UInt64 = 0
            var secondsUsed: TimeInterval = 0
            let responseArr: [STAResponse] = STAResponse.analysisiBuffer(one.data, byteUsed: &usedLength, timeUsed: &secondsUsed)
            
            let resultToBack = STASerilaResultToBack(resultArr: responseArr, serialNum: one.workSerialNum)
            backDevData(resultToBack)
            analysisQueue.async { [weak self] in
                guard let self else { return }
                concurruntCount += 1
                concurruntCount = concurruntCount > kMaxConcurentAnalysisCount ? kMaxConcurentAnalysisCount : concurruntCount
                startAnalysisData() // 递归解析协议包
            }
        }
        startAnalysisData()
    }
    
    private func backDevData(_ resultWork: STASerilaResultToBack) {
        if let delegate {
            delegateQueue.async {
                delegate.didAnalysisOnePackage(resArr: resultWork.resultArr)
            }
        }
    }
}
