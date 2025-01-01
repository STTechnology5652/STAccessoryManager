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
            
//            if let configData = cmdResult?.workData?.responseContent {
//                let devConfig: [STARespDevConfig] = STARespDevConfig.analysisConfigData(configData)
//                let devDes = devConfig.map{$0.jsonString()}
//                STLog.debug("device config info:\(devDes)")
//            }
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
    private func updateSpeedText(_ text: String) {
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
                STLog.debug(tag: "STVC", "get on image frome device:\(img)")
//                self.updatePreviewImage(img)
            }
        }
    }
}

