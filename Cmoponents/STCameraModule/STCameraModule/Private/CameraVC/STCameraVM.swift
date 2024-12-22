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
    
    // 视频录制相关属性
    var videoWriter: AVAssetWriter?
    var videoWriterInput: AVAssetWriterInput?
    var currentVideoURL: URL?
    var recordingStartTime: Date?
    var recordingTimer: Timer?
    
    // 添加相机旋转角度状态，默认为0度
    private let cameraRotationRelay = BehaviorRelay<Int>(value: 0)
    
    // 添加滤镜状态，true 表示使用黑白滤镜
    private let isGrayscaleRelay = BehaviorRelay<Bool>(value: false)
    
    // 添加原始图像和滤镜后图像的管理
    private let originalImageRelay = BehaviorRelay<UIImage?>(value: nil)
    private let filteredImageRelay = PublishRelay<UIImage>()
    
    //MARK: - STAccessoryManager -- 相关
    var devIdentifier: String = ""
    var devHandler: STAccesoryHandlerInterface?
    
    // 添加设备状态管理
    let deviceStateRelay = PublishRelay<DeviceState>()
    let mjpegUtil = MjpegUtil()
    var speedTool = STASpeedTool()
    
    // 添加拍照事件的 Relay
    private let capturePhotoRelay = PublishRelay<UIImage>()
    
    // 添加按钮禁用状态
    private let shouldDisableButtonsRelay = BehaviorRelay<Bool>(value: false)
    
    // 添加图像数据流
    private let imageSubject = PublishSubject<UIImage>()
    
    // 添加按钮状态管理
    private let buttonStateRelay = BehaviorRelay<(isEnabled: Bool, alpha: CGFloat)>(value: (true, 1.0))
    
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
    }
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
        let cameraRotation: Driver<Int>  // 添加相机旋转角度输出
        let isGrayscale: Driver<Bool>  // 添加滤镜状态输出
        let displayImage: Driver<UIImage>  // 修改为显示图像输出
        let speedText: Driver<String>  // 添加速度文本输出
        let deviceState: Driver<DeviceState>  // 添加设备状态输出
        let capturedPhoto: Driver<UIImage>  // 添加拍照输出
        let shouldDisableButtons: Driver<Bool>  // 添加按钮禁用状态输出
        let buttonState: Driver<(isEnabled: Bool, alpha: CGFloat)>  // 添加按钮状态输出
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
                    // 如果是照片模式，发送当前图像
                    if let currentImage = self.originalImageRelay.value {
                        self.capturePhotoRelay.accept(currentImage)
                    }
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
                
                // 更新原始图像
                self.originalImageRelay.accept(image)
                
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
            buttonState: buttonStateRelay.asDriver()
        )
    }
    
    func updatePreviewImage(_ image: UIImage) {
        imageSubject.onNext(image)
    }
    
    private func updateFilteredImage() {
        guard let originalImage = originalImageRelay.value else { return }
        
        if isGrayscaleRelay.value {
            // 应用黑白滤镜
            let ciImage = CIImage(image: originalImage)
            let filter = CIFilter(name: "CIColorMonochrome")
            filter?.setValue(ciImage, forKey: kCIInputImageKey)
            filter?.setValue(CIColor(red: 0.7, green: 0.7, blue: 0.7), forKey: kCIInputColorKey)
            filter?.setValue(1.0, forKey: kCIInputIntensityKey)
            
            if let outputImage = filter?.outputImage,
               let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
                filteredImageRelay.accept(UIImage(cgImage: cgImage))
            }
        } else {
            // 使用原始图像
            filteredImageRelay.accept(originalImage)
        }
    }
}

extension STCameraVM {
    // 获取当前旋转角度
    func getCurrentRotation() -> Int {
        return cameraRotationRelay.value
    }
}
