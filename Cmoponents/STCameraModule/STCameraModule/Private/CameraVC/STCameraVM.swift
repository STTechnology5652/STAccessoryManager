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

enum STAUiEvent {
    case color
    case rotateCamera
    case rotatePhone
    case back
}

protocol STAInput {}

protocol STAOutPut {}

protocol STRxViewModelType {
    associatedtype Input
    associatedtype OutPut
    func transform(input: Input) -> OutPut
}

final class STCameraVM: NSObject, STRxViewModelType {
    private let disposeBag = DisposeBag()
    
    private let isRecordingRelay = BehaviorRelay<Bool>(value: false)
    private let isControlShowRelay = BehaviorRelay<Bool>(value: true)
    private let isPhotoModeRelay = BehaviorRelay<Bool>(value: false)
    
    private let previewImageRelay = PublishRelay<UIImage>()
    
    // 添加相机旋转角度状态，默认为0度
    private let cameraRotationRelay = BehaviorRelay<Int>(value: 0)
    
    // 添加滤镜状态，true 表示使用黑白滤镜
    private let isGrayscaleRelay = BehaviorRelay<Bool>(value: false)
    
    // 添加原始图像和滤镜后图像的管理
    private let originalImageRelay = BehaviorRelay<UIImage?>(value: nil)
    private let filteredImageRelay = PublishRelay<UIImage>()
    
    //MARK: - STAccessoryManager -- 相关
    var devIdentifier: String = ""
    private var devHandler: STAccesoryHandlerInterface?
    
    // 添加速度文本状态
    private let speedTextRelay = BehaviorRelay<String>(value: "Waiting...")
    
    // 添加设备状态管理
    private let deviceStateRelay = PublishRelay<DeviceState>()
    private let mjpegUtil = MjpegUtil()
    private var speedTool = STASpeedTool()

    // 添加拍照事件的 Relay
    private let capturePhotoRelay = PublishRelay<UIImage>()
    
    // 添加按钮禁用状态
    private let shouldDisableButtonsRelay = BehaviorRelay<Bool>(value: false)
    
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
    
    private func setupCamera() {
        checkDevState()
        closeStream()
        setStreamFormatter()
        openStream()
    }
    
    private func cleanupCamera() {
        closeStream()
    }
    
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
                    // 照片模式：拍照，不禁用按钮
                    if let currentImage = self.originalImageRelay.value {
                        self.capturePhotoRelay.accept(currentImage)
                    }
                } else {
                    // 视频模式：切换录制状态，并更新按钮禁用状态
                    let currentValue = self.isRecordingRelay.value
                    self.isRecordingRelay.accept(!currentValue)
                    self.shouldDisableButtonsRelay.accept(!currentValue)  // 录制时禁用按钮
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
        
        // 合并原始图像和滤镜后的图像
        let displayImage = Observable.merge(
            originalImageRelay.compactMap { $0 }.asObservable(),
            filteredImageRelay.asObservable()
        )
        
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
            displayImage: displayImage.asDriver(onErrorJustReturn: UIImage()),
            speedText: speedTextRelay.asDriver(),
            deviceState: deviceStateRelay.asDriver(onErrorJustReturn: .disconnected),
            capturedPhoto: capturePhotoRelay.asDriver(onErrorJustReturn: UIImage()),
            shouldDisableButtons: shouldDisableButtonsRelay.asDriver()
        )
    }
    
    func updatePreviewImage(_ image: UIImage) {
        if isGrayscaleRelay.value {
            updateFilteredImage()
        } else {
            originalImageRelay.accept(image)
        }
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


//MARK: - STAccessoryManager -- 相关
extension STCameraVM {
    func initData() {
        speedTool.startCaculted { [weak self] (speedDes: String) in
            guard let self else {
                return
            }
           
            speedTextRelay.accept("\(devIdentifier) \t: \(speedDes)/s")
        }
        
        let manager = STAccessoryManager.share()
        manager.config(delegate: self)
        manager.accessoryHander(devSerialNumber: devIdentifier) { [weak self] (result: STAccessoryWorkResult<any STAccesoryHandlerInterface>?) in
            guard let self else {
                return
            }
            
            devHandler = result?.workData
            devHandler?.configImage(receiver: self, protocol: nil, complete: { [weak self] (configResult:STAccessoryWorkResult<String>?) in
                DispatchQueue.main.async {
                    self?.checkDevState()
                }
            })
            closeStream()
            getDevConfig()
        }
    }
    
    
    private func setStreamFormatter() {
        STLog.debug()
        guard let devHandler else {
            STLog.err("no device handler")
            return
        }
        
        let cmdTag = devHandler.getNextCmdTag()
        let cmd = STACommandserialization.setStreamFormatter(cmdTag)
        let command = STAccesoryCmdData(tag: cmdTag, data: cmd)
        
        devHandler.sendCommand(command, protocol: nil) { (cmdResult:STAccessoryWorkResult<STAResponse>?) in
            STLog.debug("set stream formatter result:\(String(describing: cmdResult?.workData?.jsonString()))")
        }
    }
    
    private func getDevConfig() {
        STLog.debug()
        guard let devHandler else {
            STLog.err("no device handler")
            return
        }
        
        let cmdTag = devHandler.getNextCmdTag()
        let cmd = STACommandserialization.getDevConfig(cmdTag)
        let command = STAccesoryCmdData(tag: cmdTag, data: cmd)
        
        devHandler.sendCommand(command, protocol: nil) { (cmdResult:STAccessoryWorkResult<STAResponse>?) in
            STLog.debug("get device config result:\(String(describing: cmdResult?.workData?.jsonString()))")
            
            if let configData = cmdResult?.workData?.responseData {
                let devConfig: [STARespDevConfig] = STARespDevConfig.analysisConfigData(configData)
                let devDes = devConfig.map{$0.jsonString()}
                STLog.debug("device config info:\(devDes)")
            }
        }
    }
    
    private func openStream() {
        STLog.debug()
        devHandler?.openSteam(true, protocol: nil, complete: { (openResult:STAccessoryWorkResult<STAResponse>?) in
            STLog.debug("open stream result:\(String(describing: openResult?.workData?.jsonString()))")
        })
    }
    
    private func closeStream() {
        STLog.debug()
        devHandler?.openSteam(false, protocol: nil, complete: { (openResult:STAccessoryWorkResult<STAResponse>?) in
            STLog.debug("close stream result:\(String(describing: openResult?.workData?.jsonString()))")
        })
    }
    
    private func checkDevState() {
        if let dev = STAccessoryManager.share().connectedAccessory.filter({$0.serialNumber == devIdentifier }).first,
           dev.isConnected == true {
            STLog.info("dev enable")
            updateSpeedText("Device Connected")
            deviceStateRelay.accept(.connected)
        } else {
            updateSpeedText("Device disconnectd")
            deviceStateRelay.accept(.disconnected)
        }
    }
    
    // 更新速度文本
    func updateSpeedText(_ text: String) {
        speedTextRelay.accept(text)
    }
}


//MARK: - STAccessoryManagerDelegate
extension STCameraVM: STAccessoryConnectDelegate {
    func didConnect(device: EAAccessory) {
        checkDevState()
    }
    
    func didDisconnect(device: EAAccessory) {
        if devIdentifier == device.serialNumber { //当前正在错误的设备，需要关闭流
            
        }
        
        checkDevState()
    }
}

//MARK: - image receiver
extension STCameraVM: STAccesoryHandlerImageReceiver {
    func didReceiveDeviceImageResponse(_ imgRes: STAResponse) {
        let imgData = imgRes.imageData
        guard imgData.count > 0 else { return }
        
        // 在子线程处理图像数据
        autoreleasepool { [weak self] in
            self?.mjpegUtil.receive(NSData(data: imgData) as Data) { [weak self] (img: UIImage) in
                guard let self = self else { return }
                
                // 更新速度计数（在子线程）
                self.speedTool.appendCount(imgData.count)
                // 更新图像（在子线程）
                self.updatePreviewImage(img)
            }
        }
    }
}

extension STCameraVM {
    // 获取当前旋转角度
    func getCurrentRotation() -> Int {
        return cameraRotationRelay.value
    }
}
