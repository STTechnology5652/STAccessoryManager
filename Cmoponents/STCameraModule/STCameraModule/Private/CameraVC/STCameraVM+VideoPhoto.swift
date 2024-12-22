//
//  STCameraVM+VideoPhoto.swift
//  STCameraModule
//
//  Created by stephenchen on 2024/12/23.
//

import Foundation
import AVFoundation
import Photos
import STAllBase

// MARK: - Video Recording
extension STCameraVM {
    func startRecording() {
        guard !isRecordingRelay.value else { return }
        
        STLog.debug("开始准备录制")
        
        // 创建视频文件路径
        let videoFileName = "video_\(Date().timeIntervalSince1970).mp4"
        let videoPath = NSTemporaryDirectory().appending(videoFileName)
        currentVideoURL = URL(fileURLWithPath: videoPath)
        
        STLog.debug("视频文件路径: \(videoPath)")
        
        // 配置视频写入
        guard let videoWriter = try? AVAssetWriter(url: currentVideoURL!, fileType: .mp4) else {
            STLog.err("创建视频写入器失败")
            return
        }
        
        // 更新视频设置
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1280,
            AVVideoHeightKey: 720,
            AVVideoScalingModeKey: AVVideoScalingModeResizeAspectFill,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264Main31,
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoAllowFrameReorderingKey: false,
                AVVideoExpectedSourceFrameRateKey: 30,
                AVVideoMaxKeyFrameIntervalDurationKey: 1
            ]
        ]
        
        STLog.debug("视频设置: \(videoSettings)")
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput.expectsMediaDataInRealTime = true
        videoWriterInput.transform = CGAffineTransform(rotationAngle: 0)
        
        // 添加视频输入
        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
            STLog.debug("添加视频输入成功")
        } else {
            STLog.err("无法添加视频输入")
            return
        }
        
        self.videoWriter = videoWriter
        self.videoWriterInput = videoWriterInput
        
        // 确保开始写入成功
        guard videoWriter.startWriting() else {
            STLog.err("开始写入失败: \(videoWriter.error?.localizedDescription ?? "unknown error")")
            return
        }
        
        videoWriter.startSession(atSourceTime: .zero)
        isRecordingRelay.accept(true)
        recordingStartTime = Date()
        
        STLog.debug("录制准备完成，开始计时")
        startRecordingTimer()
    }
    
    func stopRecording(completion: @escaping (Bool) -> Void) {
        guard isRecordingRelay.value,
              let videoWriter = videoWriter,
              let currentVideoURL = currentVideoURL else {
            completion(false)
            return
        }
        
        isRecordingRelay.accept(false)
        stopRecordingTimer()
        
        videoWriterInput?.markAsFinished()
        
        // 添加日志
        STLog.debug("开始结束视频录制")
        
        videoWriter.finishWriting { [weak self] in
            guard let self = self else { return }
            
            if videoWriter.status == .completed {
                STLog.debug("视频写入完成，开始保存到相册")
                self.saveVideoToAlbum(currentVideoURL) { success in
                    if success {
                        STLog.debug("视频成功保存到相册")
                    } else {
                        STLog.err("视频保存到相册失败")
                    }
                    DispatchQueue.main.async {
                        completion(success)
                    }
                    // 清理资源
                    self.cleanupVideoRecording()
                }
            } else {
                STLog.err("视频写入失败: \(videoWriter.error?.localizedDescription ?? "unknown error")")
                DispatchQueue.main.async {
                    completion(false)
                }
                // 清理资源
                self.cleanupVideoRecording()
            }
        }
    }
    
    private func saveVideoToAlbum(_ videoURL: URL, completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                STLog.err("没有相册权限")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // 检查文件是否存在和可读
            guard FileManager.default.fileExists(atPath: videoURL.path),
                  FileManager.default.isReadableFile(atPath: videoURL.path) else {
                STLog.err("视频文件不存在或不可读")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // 打印文件信息
            if let attributes = try? FileManager.default.attributesOfItem(atPath: videoURL.path) {
                let fileSize = attributes[.size] as? Int64 ?? 0
                STLog.debug("视频文件大小: \(Double(fileSize) / 1024.0 / 1024.0) MB")
                STLog.debug("视频文件路径: \(videoURL.path)")
            }
            
            // 检查视频文件是否有效
            let asset = AVAsset(url: videoURL)
            let duration = asset.duration
            if duration.seconds < 0.1 {
                STLog.err("视频文件无效或太短")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // 使用较低质量的预设
            guard let exportSession = AVAssetExportSession(
                asset: asset,
                presetName: AVAssetExportPresetMediumQuality
            ) else {
                STLog.err("无法创建导出会话")
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }
            
            // 创建临时文件路径
            let tempFileName = "temp_video_\(Date().timeIntervalSince1970).mp4"
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(tempFileName)
            
            // 配置导出会话
            exportSession.outputURL = tempURL
            exportSession.outputFileType = .mp4
            exportSession.shouldOptimizeForNetworkUse = true
            
            STLog.debug("开始重新编码视频")
            
            exportSession.exportAsynchronously {
                DispatchQueue.main.async {
                    switch exportSession.status {
                    case .completed:
                        STLog.debug("视频重新编码完成，开始保存到相册")
                        
                        // 检查导出的文件
                        guard FileManager.default.fileExists(atPath: tempURL.path),
                              FileManager.default.isReadableFile(atPath: tempURL.path) else {
                            STLog.err("导出的视频文件不存在或不可读")
                            completion(false)
                            return
                        }
                        
                        // 保存重新编码后的视频
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                        }) { success, error in
                            // 清理临时文件
                            try? FileManager.default.removeItem(at: tempURL)
                            
                            if success {
                                STLog.debug("视频保存到相册成功")
                            } else {
                                STLog.err("视频保存到相册失败: \(error?.localizedDescription ?? "unknown error")")
                            }
                            DispatchQueue.main.async {
                                completion(success)
                            }
                        }
                        
                    case .failed:
                        let error = exportSession.error
                        STLog.err("视频导出失败: \(error?.localizedDescription ?? "unknown error")")
                        if let error = error as NSError? {
                            STLog.err("错误域: \(error.domain)")
                            STLog.err("错误码: \(error.code)")
                            STLog.err("错误信息: \(error.userInfo)")
                        }
                        try? FileManager.default.removeItem(at: tempURL)
                        completion(false)
                        
                    case .cancelled:
                        STLog.err("视频导出被取消")
                        try? FileManager.default.removeItem(at: tempURL)
                        completion(false)
                        
                    default:
                        STLog.err("视频导出状态异常: \(exportSession.status.rawValue)")
                        try? FileManager.default.removeItem(at: tempURL)
                        completion(false)
                    }
                }
            }
        }
    }
    
    private func cleanupVideoRecording() {
        // 清理临时文件
        if let url = currentVideoURL {
            do {
                try FileManager.default.removeItem(at: url)
                STLog.debug("成功删除临时视频文件")
            } catch {
                STLog.err("删除临时视频文件失败: \(error.localizedDescription)")
            }
        }
        
        // 重置状态
        videoWriter = nil
        videoWriterInput = nil
        currentVideoURL = nil
        recordingStartTime = nil
    }
    
    // MARK: - Recording Timer
    private func startRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateRecordingDuration()
        }
    }
    
    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    private func updateRecordingDuration() {
        guard let startTime = recordingStartTime else { return }
        let duration = Int(Date().timeIntervalSince(startTime))
        let minutes = duration / 60
        let seconds = duration % 60
        speedTextRelay.accept(String(format: "录制时长: %02d:%02d", minutes, seconds))
    }
}

// MARK: - Video Frame Processing
extension STCameraVM {
    private static let videoProcessingQueue = DispatchQueue(label: "com.st.camera.videoProcessing")
    
    func processVideoFrame(_ image: UIImage) {
        guard isRecordingRelay.value,
              let videoWriterInput = videoWriterInput else {
            return
        }
        
        // 将图像转换为视频帧
        guard let pixelBuffer = image.toPixelBuffer() else {
            STLog.err("Failed to convert image to pixel buffer")
            return
        }
        
        Self.videoProcessingQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 创建 CMSampleBuffer
            var sampleBuffer: CMSampleBuffer?
            var timimgInfo = CMSampleTimingInfo()
            
            // 使用更精确的时间戳
            let timestamp = Date().timeIntervalSince(self.recordingStartTime!)
            timimgInfo.duration = CMTime(value: 1, timescale: 30)
            timimgInfo.presentationTimeStamp = CMTime(seconds: timestamp, preferredTimescale: 90000)
            timimgInfo.decodeTimeStamp = .invalid
            
            var formatDescription: CMFormatDescription?
            let status = CMVideoFormatDescriptionCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                formatDescriptionOut: &formatDescription
            )
            
            guard status == noErr, let formatDescription = formatDescription else {
                STLog.err("Failed to create format description")
                return
            }
            
            let createStatus = CMSampleBufferCreateForImageBuffer(
                allocator: kCFAllocatorDefault,
                imageBuffer: pixelBuffer,
                dataReady: true,
                makeDataReadyCallback: nil,
                refcon: nil,
                formatDescription: formatDescription,
                sampleTiming: &timimgInfo,
                sampleBufferOut: &sampleBuffer
            )
            
            guard createStatus == noErr, let sampleBuffer = sampleBuffer else {
                STLog.err("Failed to create sample buffer")
                return
            }
            
            // 等待写入器准备好
            while !videoWriterInput.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.001) // 等待1毫秒
            }
            
            if !videoWriterInput.append(sampleBuffer) {
                STLog.err("Failed to write video frame")
            }
        }
    }
}

// MARK: - Helper Extensions
private extension UIImage {
    func toPixelBuffer() -> CVPixelBuffer? {
        guard let cgImage = self.cgImage else {
            STLog.err("无法获取 CGImage")
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferMetalCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attrs,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            STLog.err("创建像素缓冲区失败: \(status)")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            STLog.err("创建 CGContext 失败")
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return buffer
    }
} 
