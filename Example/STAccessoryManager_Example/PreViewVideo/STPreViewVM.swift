//
//  STPreViewVM.swift
//  STAccessoryManager_Example
//
//  Created by stephenchen on 2024/12/17.
//

import UIKit
import RxSwift
import RxCocoa
import STAccessoryManager

enum PreViewEvent {
    case getImage(image: UIImage)
    case configResult(success: Bool)
}

protocol STViewModelType {
    associatedtype Input
    associatedtype OutPut
    func transform(input: Input) -> OutPut
}

struct STPreViewInput {
    let getDevConfig: Observable<Void>
    
}

struct STPreviewOutPut {
    let imageOutPut: BehaviorRelay<UIImage>
}

class STPreViewVM: NSObject, STViewModelType  {
    private let disposeBag = DisposeBag()
    
    typealias Input = STPreViewInput
    typealias OutPut = STPreviewOutPut
    
    private var outPut: STPreviewOutPut?
    
    private var handler: STAccesoryHandlerInterface?
    
    func transform(input: STPreViewInput) -> STPreviewOutPut {
        prepareWork()
        
        let imageOutPut = BehaviorRelay(value: UIImage())
        input.getDevConfig.subscribe(onNext: { [weak self] in
            self?.getDevConfig()
        }).disposed(by: disposeBag)
        
        return OutPut(
            imageOutPut: imageOutPut
        )
    }
    
    private func getDevConfig() {
        guard let devHandler = handler else {return}
        
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
    
    func prepareWork() {
        STAccessoryManager.share().config(delegate: self)
            .accessoryHander(devSerialNumber: devIdentifier) { (handlerResult: STAccessoryWorkResult<any STAccesoryHandlerInterface>?) in
                guard let handler = handlerResult?.workData else { // 获取设备句柄失败
                    return
                }
                
                // 配置图像接收的delegate
                handler.configImage(receiver: self, protocol: nil) { [weak self] (configImageReceiveResult: STAccessoryWorkResult<String>?) in
                    if configImageReceiveResult?.status == false, let hand = handlerResult?.workData {
                        return
                    }
                    self?.handler = handler
                }
            }
    }
    
    let devIdentifier: String
    
    init(devIdentifier: String) {
        self.devIdentifier = devIdentifier
        super.init()
    }
    
    func startReceiveImage() {
        
    }
    
    func prepareVM() {
        STAccessoryManager.share().config(delegate: self)
            .accessoryHander(devSerialNumber: devIdentifier) { (result: STAccessoryWorkResult<any STAccesoryHandlerInterface>?) in
                
            }
    }
    
}

//MARK: - STAccessoryManagerDelegate
extension STPreViewVM: STAccessoryConnectDelegate {
    func didConnect(device: EAAccessory) {
    }
    
    func didDisconnect(device: EAAccessory) {
        if devIdentifier == device.serialNumber { //当前正在错误的设备，需要关闭流
            
        }
    }
}

//mark: - image receivew
extension STPreViewVM: STAccesoryHandlerImageReceiver {
    func didReceiveDeviceImageResponse(_ imgRes: STAResponse) {
        
    }
}
