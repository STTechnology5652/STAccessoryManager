import Foundation
import AVFoundation
import STAllBase

class STH264StreamPlayer {
    private var formatDescription: CMFormatDescription?
    private var spsData: Data?
    private var ppsData: Data?
    private let displayLayer = AVSampleBufferDisplayLayer()
    private let queue = DispatchQueue(label: "com.st.h264.player", qos: .userInteractive)
    private var currentPTS = CMTime.zero
    private var pendingBuffers: [CMSampleBuffer] = []
    private let bufferLock = NSLock()
    
    init() {
        // 配置显示层
        displayLayer.videoGravity = .resizeAspectFill
        
        // 设置控制时基
        var timebase: CMTimebase?
        if CMTimebaseCreateWithSourceClock(
            allocator: kCFAllocatorDefault,
            sourceClock: CMClockGetHostTimeClock(),
            timebaseOut: &timebase
        ) == noErr, let timebase = timebase {
            displayLayer.controlTimebase = timebase
            CMTimebaseSetTime(timebase, time: .zero)
            CMTimebaseSetRate(timebase, rate: 1.0)
        }
        
        // 开始请求媒体数据
        displayLayer.requestMediaDataWhenReady(on: queue) { [weak self] in
            guard let self = self else { return }
            
            while self.displayLayer.isReadyForMoreMediaData {
                self.bufferLock.lock()
                guard !self.pendingBuffers.isEmpty else {
                    self.bufferLock.unlock()
                    break
                }
                
                let buffer = self.pendingBuffers.removeFirst()
                self.bufferLock.unlock()
                
                self.displayLayer.enqueue(buffer)
            }
        }
    }
    
    deinit {
        displayLayer.stopRequestingMediaData()
        displayLayer.flush()
    }
    
    func processH264Data(_ data: Data) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // 检查是否是 SPS 或 PPS
            if self.isParameterSet(data) {
                self.handleParameterSet(data)
                return
            }
            
            // 确保我们有格式描述
            guard let formatDescription = self.formatDescription else {
                STLog.err("No format description available")
                return
            }
            
            // 创建 CMBlockBuffer
            var blockBuffer: CMBlockBuffer?
            var sampleBuffer: CMSampleBuffer?
            
            // 移除起始码
            let nalData = data.dropFirst(4)
            
            let status = nalData.withUnsafeBytes { (buffer: UnsafeRawBufferPointer) -> OSStatus in
                let length = nalData.count
                let memoryBlock = UnsafeMutablePointer<UInt8>.allocate(capacity: length)
                memcpy(memoryBlock, buffer.baseAddress!, length)
                
                return CMBlockBufferCreateWithMemoryBlock(
                    allocator: kCFAllocatorDefault,
                    memoryBlock: memoryBlock,
                    blockLength: length,
                    blockAllocator: nil,
                    customBlockSource: nil,
                    offsetToData: 0,
                    dataLength: length,
                    flags: 0,
                    blockBufferOut: &blockBuffer
                )
            }
            
            guard status == noErr, let blockBuffer = blockBuffer else {
                STLog.err("Failed to create block buffer: \(status)")
                return
            }
            
            // 创建时间信息
            var timingInfo = CMSampleTimingInfo(
                duration: CMTimeMake(value: 1, timescale: 30),
                presentationTimeStamp: self.currentPTS,
                decodeTimeStamp: CMTimeMake(value: self.currentPTS.value, timescale: 30)
            )
            
            let status2 = CMSampleBufferCreateReady(
                allocator: kCFAllocatorDefault,
                dataBuffer: blockBuffer,
                formatDescription: formatDescription,
                sampleCount: 1,
                sampleTimingEntryCount: 1,
                sampleTimingArray: &timingInfo,
                sampleSizeEntryCount: 0,
                sampleSizeArray: nil,
                sampleBufferOut: &sampleBuffer
            )
            
            guard status2 == noErr, let sampleBuffer = sampleBuffer else {
                STLog.err("Failed to create sample buffer: \(status2)")
                return
            }
            
            // 更新时间戳
            self.currentPTS = CMTimeAdd(self.currentPTS, CMTimeMake(value: 1, timescale: 30))
            
            // 将样本缓冲区添加到待处理队列
            self.bufferLock.lock()
            self.pendingBuffers.append(sampleBuffer)
            self.bufferLock.unlock()
        }
    }
    
    func getDisplayLayer() -> AVSampleBufferDisplayLayer {
        return displayLayer
    }
    
    private func isParameterSet(_ data: Data) -> Bool {
        guard data.count > 4 else { return false }
        let naluType = data[4] & 0x1F
        return naluType == 7 || naluType == 8 // 7 是 SPS，8 是 PPS
    }
    
    private func handleParameterSet(_ data: Data) {
        let naluType = data[4] & 0x1F
        if naluType == 7 {
            spsData = data
        } else if naluType == 8 {
            ppsData = data
        }
        
        if let sps = spsData, let pps = ppsData {
            createFormatDescription(sps: sps, pps: pps)
        }
    }
    
    private func createFormatDescription(sps: Data, pps: Data) {
        // 移除起始码
        let spsData = sps.dropFirst(4)
        let ppsData = pps.dropFirst(4)
        
        var parameterSets: [Data] = []
        parameterSets.append(spsData)
        parameterSets.append(ppsData)
        
        let pointers: [UnsafePointer<UInt8>] = parameterSets.map { data in
            data.withUnsafeBytes { buffer in
                buffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
            }
        }
        
        let sizes = parameterSets.map { $0.count }
        
        let status = pointers.withUnsafeBufferPointer { pointerBuffer in
            sizes.withUnsafeBufferPointer { sizeBuffer in
                CMVideoFormatDescriptionCreateFromH264ParameterSets(
                    allocator: kCFAllocatorDefault,
                    parameterSetCount: 2,
                    parameterSetPointers: pointerBuffer.baseAddress!,
                    parameterSetSizes: sizeBuffer.baseAddress!,
                    nalUnitHeaderLength: 4,
                    formatDescriptionOut: &formatDescription
                )
            }
        }
        
        if status != noErr {
            STLog.err("Failed to create format description: \(status)")
        }
    }
} 
