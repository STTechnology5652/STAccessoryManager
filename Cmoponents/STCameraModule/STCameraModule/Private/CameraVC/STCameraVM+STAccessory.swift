//
//  STCameraVM+STAccessory.swift
//  STCameraModule
//
//  Created by stephenchen on 2024/12/23.
//

import STAccessoryManager

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
    
    func setupCamera() {
        checkDevState()
        closeStream()
        setStreamFormatter()
        openStream()
    }
    
    func cleanupCamera() {
        closeStream()
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
        guard let devHandler = devHandler else {
            STLog.err("设备未连接")
            handleDeviceError(.deviceNotFound)
            return
        }
        
        // 更新UI状态
        buttonStateRelay.accept((false, 0.5))
        cameraStateRelay.accept(.processing)
        STLog.debug("开始打开设备流")
        
        // 创建超时定时器
        let timeoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            self?.handleDeviceError(.timeout)
        }
        
        devHandler.openSteam(true, protocol: nil) { [weak self] (openResult: STAccessoryWorkResult<STAResponse>?) in
            // 取消超时定时器
            timeoutTimer.invalidate()
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let response = openResult?.workData {
                    STLog.debug("设备流打开成功")
                    self.handleStreamOpenSuccess(response)
                } else {
                    let error = DeviceOperationError.openStreamFailed(openResult?.workDes)
                    self.handleDeviceError(error)
                }
            }
        }
    }
    
    private func handleStreamOpenSuccess(_ response: STAResponse) {
        STLog.debug("Stream opened successfully: \(response.jsonString())")
        buttonStateRelay.accept((true, 1.0))
        cameraStateRelay.accept(.ready)
    }
    
    private func handleDeviceError(_ error: DeviceOperationError) {
        STLog.err(error.message)
        
        // 更新状态
        buttonStateRelay.accept((true, 1.0))
        cameraStateRelay.accept(.error(error))
        
        // 发送错误通知
        let alert = DeviceAlert(
            title: "设备错误".stLocalLized,
            message: error.message,
            actions: [
                ("重试".stLocalLized, false),
                ("退出".stLocalLized, true)
            ]
        )
        
        // 通知 UI 显示错误
        deviceAlertRelay.accept(alert)
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
            updateSpeedText("设备已连接".stLocalLized)
            deviceStateRelay.accept(.connected)
        } else {
            updateSpeedText("设备已断开".stLocalLized)
            deviceStateRelay.accept(.disconnected)
        }
    }
    
    // 更新速度文本
    private func updateSpeedText(_ text: String) {
        speedTextRelay.accept(text)
    }
    
    func retryOpenStream() {
        STLog.debug("重试打开设备流")
        openStream()
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

// 添加设备操作错误类型
enum DeviceOperationError: Error {
    case timeout
    case openStreamFailed(String?)
    case deviceNotFound
    
    var message: String {
        switch self {
        case .timeout:
            return "开启设备超时".stLocalLized
        case .openStreamFailed(let error):
            return String(format: "开启设备失败: %@".stLocalLized, 
                        error ?? "未知错误".stLocalLized)
        case .deviceNotFound:
            return "设备未连接".stLocalLized
        }
    }
}

