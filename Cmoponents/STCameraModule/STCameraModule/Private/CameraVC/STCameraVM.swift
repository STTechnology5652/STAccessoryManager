//
//  STCameraVM.swift
//  STCameraModule
//
//  Created by stephenchen on 2024/12/22.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay
import STLog
import AVFoundation

import STAccessoryManager

protocol STAInput {}

protocol STAOutPut {}

protocol STRxViewModelType {
    associatedtype Input
    associatedtype OutPut
    func transform(input: Input) -> OutPut
}

final class STCameraVM: NSObject, STRxViewModelType {
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    
    // Relay Properties
    let isRecordingRelay = BehaviorRelay<Bool>(value: false)
    let isControlShowRelay = BehaviorRelay<Bool>(value: true)
    let isPhotoModeRelay = BehaviorRelay<Bool>(value: false)
    let speedTextRelay = BehaviorRelay<String>(value: "Waiting...")
    let previewImageRelay = PublishRelay<UIImage>()
    let deviceStateRelay = PublishRelay<DeviceState>()
    let buttonStateRelay = BehaviorRelay<(isEnabled: Bool, alpha: CGFloat)>(value: (true, 1.0))
    let cameraStateRelay = BehaviorRelay<CameraState>(value: .initial)
    let deviceAlertRelay = PublishRelay<DeviceAlert>()
    private let capturePhotoRelay = PublishRelay<UIImage>()
    private let shouldDisableButtonsRelay = BehaviorRelay<Bool>(value: false)
    private let filteredImageRelay = PublishRelay<UIImage>()
    private let imageSubject = PublishSubject<UIImage>()
    private let cameraRotationRelay = BehaviorRelay<Int>(value: 0)
    private let isGrayscaleRelay = BehaviorRelay<Bool>(value: false)
    private let h264DataRelay = PublishRelay<Data>()
    
    // 视频录制相关属性
    var videoWriter: AVAssetWriter?
    var videoWriterInput: AVAssetWriterInput?
    var currentVideoURL: URL?
    var recordingStartTime: Date?
    var recordingTimer: Timer?
    
    //MARK: - STAccessoryManager -- 相关
    var devIdentifier: String = ""
    var devHandler: STAccesoryHandlerInterface?
    
    // 添加设备状态管理
    let mjpegUtil = MjpegUtil()
    var speedTool = STASpeedTool()
    
    // 添加相机状态枚举
    enum CameraState: Equatable {
        case initial        // 初始状态
        case ready         // 准备就绪
        case capturing     // 拍照中
        case recording     // 录制中
        case processing    // 处理中
        case error(Error)  // 错误状态
        
        // 实现 Equatable 协议
        static func == (lhs: CameraState, rhs: CameraState) -> Bool {
            switch (lhs, rhs) {
            case (.initial, .initial),
                 (.ready, .ready),
                 (.capturing, .capturing),
                 (.recording, .recording),
                 (.processing, .processing):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }
    
    enum DeviceState {
        case connected
        case disconnected
    }
    
    struct DeviceAlert {
        let title: String
        let message: String
        let actions: [(String, Bool)]  // (title, isCancel)
    }
    
    deinit {
        STLog.debug("STCameraVM deinit")
        cleanupResources()
    }
    
    private var h264Converter: STH264Converter?
}

extension STCameraVM {
    
    // MARK: - Lifecycle Methods
    func viewWillAppear() {
        STLog.debug("相机页面即将显示")
        setupCamera()
    }
    
    func viewDidDisappear() {
        STLog.debug("相机页面已经消失")
        cleanupCamera()
    }
    
    // MARK: - Input/Output
    struct STCameraInput {
        let btnColor: Driver<Void>
        let btnRotateCamera: Driver<Void>
        let btnRotatePhone: Driver<Void>
        let btnStart: Driver<Void>
        let controlTap: Driver<Void>
        let btnPhoto: Driver<Void>
        let btnVideo: Driver<Void>
    }
    
    struct STCameraOutput {
        let btnColor: Driver<Void>
        let btnRotateCamera: Driver<Void>
        let btnRotatePhone: Driver<Void>
        let isRecording: Driver<Bool>
        let isControlShow: Driver<Bool>
        let isPhotoMode: Driver<Bool>
        let previewImage: Driver<UIImage>
        let cameraRotation: Driver<Int>
        let isGrayscale: Driver<Bool>
        let displayImage: Driver<UIImage>
        let speedText: Driver<String>
        let deviceState: Driver<DeviceState>
        let capturedPhoto: Driver<UIImage>
        let shouldDisableButtons: Driver<Bool>
        let buttonState: Driver<(isEnabled: Bool, alpha: CGFloat)>
        let deviceAlert: Driver<DeviceAlert>
        let h264Data: Driver<Data>
    }
    
    typealias Input = STCameraInput
    typealias OutPut = STCameraOutput
    
    func transform(input: STCameraInput) -> STCameraOutput {
        // 处理开始按钮点击
        input.btnStart
            .withLatestFrom(isPhotoModeRelay.asDriver())
            .do(onNext: { [weak self] isPhotoMode in
                guard let self = self else { return }
                if isPhotoMode {
                    // 如果是照片模式，使用 imageSubject 的最新值
                    imageSubject
                        .take(1)
                        .subscribe(onNext: { [weak self] image in
                            self?.capturePhotoRelay.accept(image)
                        })
                        .disposed(by: disposeBag)
                } else {
                    // 如果是视频模式，切换录制状态
                    let currentValue = self.isRecordingRelay.value
                    if currentValue {
                        self.stopRecording { _ in }
                    } else {
                        self.startRecording()
                    }
                }
            })
            .drive()
            .disposed(by: disposeBag)
        
        input.controlTap
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let currentValue = self.isControlShowRelay.value
                self.isControlShowRelay.accept(!currentValue)
            })
            .disposed(by: disposeBag)
        
        input.btnPhoto
            .drive(onNext: { [weak self] in
                self?.isPhotoModeRelay.accept(true)
            })
            .disposed(by: disposeBag)
        
        input.btnVideo
            .drive(onNext: { [weak self] in
                self?.isPhotoModeRelay.accept(false)
            })
            .disposed(by: disposeBag)
        
        // 处理相机旋转按钮点击
        input.btnRotateCamera
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                // 获取当前角度并加90度
                let currentRotation = self.cameraRotationRelay.value
                let newRotation = (currentRotation + 90) % 360
                self.cameraRotationRelay.accept(newRotation)
            })
            .disposed(by: disposeBag)
        
        // 处理颜色按钮点击
        input.btnColor
            .drive(onNext: { [weak self] in
                guard let self = self else { return }
                let currentValue = self.isGrayscaleRelay.value
                self.isGrayscaleRelay.accept(!currentValue)
                self.updateFilteredImage()  // 更新滤镜图像
            })
            .disposed(by: disposeBag)
        
        // 监听滤镜状态变化
        isGrayscaleRelay
            .skip(1)  // 跳过初始值
            .subscribe(onNext: { [weak self] _ in
                self?.updateFilteredImage()
            })
            .disposed(by: disposeBag)
        
        // 处理图像数据流
        imageSubject
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] image in
                guard let self = self else { return }
                
                // 如果正在录制视频，处理视频帧
                if self.isRecordingRelay.value {
                    self.processVideoFrame(image)
                }
                
                self.filteredImageRelay.accept(image)
            })
            .disposed(by: disposeBag)
        
        // 移除 speedTool.rxSpeed 相关代码，使用原有的回调
        speedTool.startCaculted { [weak self] speedDes in
            guard let self = self else { return }
            // 只在非录制状态下显示速度
            if !self.isRecordingRelay.value {
                self.speedTextRelay.accept("\(self.devIdentifier) \t: \(speedDes)/s")
            }
        }
        
        // 处理按钮状态
        Observable.combineLatest(
            isRecordingRelay.asObservable(),
            isPhotoModeRelay.asObservable()
        )
        .map { isRecording, isPhotoMode -> (isEnabled: Bool, alpha: CGFloat) in
            // 在视频模式下录制时禁用按钮
            let shouldDisable = !isPhotoMode && isRecording
            return (!shouldDisable, shouldDisable ? 0.5 : 1.0)
        }
        .bind(to: buttonStateRelay)
        .disposed(by: disposeBag)
        
        return STCameraOutput(
            btnColor: input.btnColor,
            btnRotateCamera: input.btnRotateCamera,
            btnRotatePhone: input.btnRotatePhone,
            isRecording: isRecordingRelay.asDriver(),
            isControlShow: isControlShowRelay.asDriver(),
            isPhotoMode: isPhotoModeRelay.asDriver(),
            previewImage: previewImageRelay.asDriver(onErrorJustReturn: UIImage()),
            cameraRotation: cameraRotationRelay.asDriver(),
            isGrayscale: isGrayscaleRelay.asDriver(),
            displayImage: filteredImageRelay.asDriver(onErrorJustReturn: UIImage()),
            speedText: speedTextRelay.asDriver(),
            deviceState: deviceStateRelay.asDriver(onErrorJustReturn: .disconnected),
            capturedPhoto: capturePhotoRelay.asDriver(onErrorJustReturn: UIImage()),
            shouldDisableButtons: shouldDisableButtonsRelay.asDriver(),
            buttonState: buttonStateRelay.asDriver(),
            deviceAlert: deviceAlertRelay.asDriver(onErrorJustReturn: DeviceAlert(
                title: "错误",
                message: "未知错误",
                actions: [("确定", true)]
            )),
            h264Data: h264DataRelay.asDriver(onErrorJustReturn: Data())
        )
    }
    
    func updatePreviewImage(_ image: UIImage) {
        // 更新设备状态为已连接
        deviceStateRelay.accept(.connected)
        
        imageSubject.onNext(image)
        
        // 转换为 H264
        if h264Converter == nil {
            STLog.debug("Creating H264 converter with size: \(image.size)")
            h264Converter = STH264Converter(width: Int32(image.size.width), height: Int32(image.size.height))
            h264Converter?.setCallback { [weak self] data in
                STLog.debug("H264 data received: \(data.count) bytes")
                self?.h264DataRelay.accept(data)
            }
        }
        
        if let pixelBuffer = image.toPixelBuffer() {
            h264Converter?.encode(pixelBuffer: pixelBuffer)
        } else {
            STLog.err("Failed to create pixel buffer from image")
        }
    }
    
    private func updateFilteredImage() {
        imageSubject
            .take(1)
            .subscribe(onNext: { [weak self] image in
                guard let self = self else { return }
                
                if self.isGrayscaleRelay.value {
                    // 应用黑白滤镜
                    let ciImage = CIImage(image: image)
                    let filter = CIFilter(name: "CIColorMonochrome")
                    filter?.setValue(ciImage, forKey: kCIInputImageKey)
                    filter?.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: kCIInputColorKey)
                    filter?.setValue(1.0, forKey: kCIInputIntensityKey)
                    
                    if let outputImage = filter?.outputImage,
                       let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
                        self.filteredImageRelay.accept(UIImage(cgImage: cgImage))
                    }
                } else {
                    // 使用原始图像
                    self.filteredImageRelay.accept(image)
                }
            })
            .disposed(by: disposeBag)
    }
    
    // 添加状态监听
    private func observeCameraState() {
        cameraStateRelay
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] state in
                self?.handleCameraStateChange(state)
            })
            .disposed(by: disposeBag)
    }
    
    private func handleCameraStateChange(_ state: CameraState) {
        switch state {
        case .initial:
            buttonStateRelay.accept((true, 1.0))
        case .ready:
            buttonStateRelay.accept((true, 1.0))
        case .capturing, .recording, .processing:
            buttonStateRelay.accept((false, 0.5))
        case .error:
            buttonStateRelay.accept((true, 1.0))
            // 显示错误提示
        }
    }
    
    // 添加资源清理方法
    private func cleanupResources() {
        // 停止定时器
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // 清理视频相关资源
        videoWriter = nil
        videoWriterInput = nil
        
        // 清理 H264 编码器
        h264Converter = nil
        
        // 重置状态
        isRecordingRelay.accept(false)
        cameraStateRelay.accept(.initial)
        
        // 更新设备状态为断开连接
        deviceStateRelay.accept(.disconnected)
    }
}

extension STCameraVM {
    // 获取当前旋转角度
    func getCurrentRotation() -> Int {
        return cameraRotationRelay.value
    }
}
