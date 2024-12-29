//
//  STH264Contert.swift
//  STCameraModule
//
//  Created by stephenchen on 2024/12/30.
//

import Foundation
import VideoToolbox
import AVFoundation
import STAllBase

class STH264Converter {
    private var encoderSession: VTCompressionSession?
    fileprivate var callback: ((Data) -> Void)?
    private let width: Int32
    private let height: Int32
    private let fps: Int32
    private let bitrate: Int32
    private var frameCount: Int64 = 0
    private var formatDescription: CMFormatDescription?
    private let encodeQueue = DispatchQueue(label: "com.st.h264.encoder")
    
    init(width: Int32, height: Int32, fps: Int32 = 30, bitrate: Int32 = 1024 * 1000) {
        self.width = width
        self.height = height
        self.fps = fps
        self.bitrate = bitrate
        setupEncoder()
    }
    
    deinit {
        if let session = encoderSession {
            VTCompressionSessionCompleteFrames(session, untilPresentationTimeStamp: .invalid)
            VTCompressionSessionInvalidate(session)
        }
    }
    
    func setCallback(_ callback: @escaping (Data) -> Void) {
        self.callback = callback
    }
    
    private func setupEncoder() {
        var session: VTCompressionSession?
        
        // 创建编码器配置
        let encoderSpecification: [CFString: Any]
        if #available(iOS 17.4, *) {
            encoderSpecification = [
                kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder: true,
                kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder: true
            ]
        } else {
            encoderSpecification = [:]
        }
        
        let status = VTCompressionSessionCreate(
            allocator: kCFAllocatorDefault,
            width: width,
            height: height,
            codecType: kCMVideoCodecType_H264,
            encoderSpecification: encoderSpecification as CFDictionary,
            imageBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
                kCVPixelBufferIOSurfacePropertiesKey: [:],
                kCVPixelBufferMetalCompatibilityKey: true
            ] as CFDictionary,
            compressedDataAllocator: nil,
            outputCallback: nil,
            refcon: nil,
            compressionSessionOut: &session
        )
        
        guard status == noErr, let session = session else {
            STLog.err("Failed to create compression session: \(status)")
            return
        }
        
        encoderSession = session
        
        // 设置编码参数
        let properties: [CFString: Any] = [
            kVTCompressionPropertyKey_RealTime: true,
            kVTCompressionPropertyKey_ProfileLevel: kVTProfileLevel_H264_Baseline_AutoLevel,
            kVTCompressionPropertyKey_AverageBitRate: bitrate,
            kVTCompressionPropertyKey_ExpectedFrameRate: fps,
            kVTCompressionPropertyKey_AllowFrameReordering: false,
            kVTCompressionPropertyKey_MaxKeyFrameInterval: 30,
            kVTCompressionPropertyKey_H264EntropyMode: kVTH264EntropyMode_CAVLC
        ]
        
        for (key, value) in properties {
            VTSessionSetProperty(session, key: key, value: value as CFTypeRef)
        }
        
        // 确保编码器准备就绪
        let prepareStatus = VTCompressionSessionPrepareToEncodeFrames(session)
        if prepareStatus != noErr {
            STLog.err("Failed to prepare encoder: \(prepareStatus)")
        }
    }
    
    func encode(pixelBuffer: CVPixelBuffer) {
        encodeQueue.async { [weak self] in
            guard let self = self,
                  let session = self.encoderSession else { return }
            
            let presentationTime = CMTimeMake(value: self.frameCount, timescale: self.fps)
            let duration = CMTimeMake(value: 1, timescale: self.fps)
            
            var properties: [String: Any] = [:]
            if self.frameCount % 30 == 0 {
                properties[kVTEncodeFrameOptionKey_ForceKeyFrame as String] = true
            }
            
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
            
            let status = VTCompressionSessionEncodeFrame(
                session,
                imageBuffer: pixelBuffer,
                presentationTimeStamp: presentationTime,
                duration: duration,
                frameProperties: properties as CFDictionary,
                infoFlagsOut: nil,
                outputHandler: { [weak self] status, flags, sampleBuffer in
                    guard let self = self else { return }
                    guard status == noErr else {
                        STLog.err("Encode callback error: \(status)")
                        return
                    }
                    guard let sampleBuffer = sampleBuffer else {
                        STLog.err("No sample buffer")
                        return
                    }
                    
                    guard CMSampleBufferDataIsReady(sampleBuffer) else {
                        STLog.err("Sample buffer is not ready")
                        return
                    }
                    
                    // 处理关键帧
                    if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: false) as? [[CFString: Any]],
                       let attachment = attachments.first {
                        let isKeyframe = (attachment[kCMSampleAttachmentKey_DependsOnOthers] as? Bool) == false
                        
                        if isKeyframe {
                            if let description = CMSampleBufferGetFormatDescription(sampleBuffer),
                               var spsData = self.getSPSData(from: description),
                               var ppsData = self.getPPSData(from: description) {
                                
                                let startCode = Data([0x00, 0x00, 0x00, 0x01])
                                spsData.insert(contentsOf: startCode, at: 0)
                                ppsData.insert(contentsOf: startCode, at: 0)
                                
                                self.callback?(spsData)
                                self.callback?(ppsData)
                            }
                        }
                    }
                    
                    // 获取编码后的数据
                    guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
                    
                    var length: Int = 0
                    var dataPointer: UnsafeMutablePointer<Int8>?
                    let status2 = CMBlockBufferGetDataPointer(
                        dataBuffer,
                        atOffset: 0,
                        lengthAtOffsetOut: nil,
                        totalLengthOut: &length,
                        dataPointerOut: &dataPointer
                    )
                    
                    guard status2 == noErr, let dataPointer = dataPointer else { return }
                    
                    let startCode = Data([0x00, 0x00, 0x00, 0x01])
                    var data = Data(startCode)
                    data.append(UnsafeBufferPointer(start: dataPointer, count: length))
                    
                    self.callback?(data)
                }
            )
            
            if status != noErr {
                STLog.err("Failed to encode frame: \(status)")
                return
            }
            
            self.frameCount += 1
        }
    }
    
    fileprivate func getSPSData(from formatDescription: CMFormatDescription) -> Data? {
        var parameterSetCount = 0
        var parameterSetPointer: UnsafePointer<UInt8>?
        var parameterSetSize: Int = 0
        
        let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 0,
            parameterSetPointerOut: &parameterSetPointer,
            parameterSetSizeOut: &parameterSetSize,
            parameterSetCountOut: &parameterSetCount,
            nalUnitHeaderLengthOut: nil
        )
        
        guard status == noErr,
              let pointer = parameterSetPointer else { return nil }
        
        return Data(bytes: pointer, count: parameterSetSize)
    }
    
    fileprivate func getPPSData(from formatDescription: CMFormatDescription) -> Data? {
        var parameterSetCount = 0
        var parameterSetPointer: UnsafePointer<UInt8>?
        var parameterSetSize: Int = 0
        
        let status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(
            formatDescription,
            parameterSetIndex: 1,
            parameterSetPointerOut: &parameterSetPointer,
            parameterSetSizeOut: &parameterSetSize,
            parameterSetCountOut: &parameterSetCount,
            nalUnitHeaderLengthOut: nil
        )
        
        guard status == noErr,
              let pointer = parameterSetPointer else { return nil }
        
        return Data(bytes: pointer, count: parameterSetSize)
    }
}
