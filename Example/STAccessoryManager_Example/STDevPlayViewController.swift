//
//  STDevPlayViewController.swift
//  STAccessoryManager_Example
//
//  Created by stephenchen on 2024/11/16.
//

import UIKit
import STAccessoryManager
import SnapKit
import SwiftUI

class STDevPlayViewController: UIViewController {
    var devIdentifier: String = ""
    private var devHandler: STAccesoryHandlerInterface?
    private var speedTool = STASpeedTool()
    private let mjpegUtil = MjpegUtil()
    
    @IBOutlet weak var labStreamInfo: UILabel!
    @IBOutlet weak var controlBackView: UIView!
    @IBOutlet weak var btnSaveLog: UIButton!
    @IBOutlet weak var imgPreView: UIImageView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        initData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }
    
    private func setUpUI() {
        let tapGes = UITapGestureRecognizer(target: self, action: #selector(self.uiActionControlBackTaped(_:)))
        view.addGestureRecognizer(tapGes)
        btnSaveLog.setTitle(btnSaveLog.isSelected ? "Log Writing" : "Log Print", for: .normal)
    }
    
    private func initData() {
        speedTool.startCaculted { [weak self] (speedDes: String) in
            guard let self else {
                return
            }
            
            labStreamInfo.text = "\(devIdentifier) \t: \(speedDes)/s"
        }
        
        Task { [weak self] in
            guard let self else {
                return
            }
            
            let manager = STAccessoryManager.share()
            manager.config(delegate: self)
            devHandler = await manager.accessoryHander(devSerialNumber: devIdentifier)
            await devHandler?.configImage(receiver: self, protocol: nil)
            
            DispatchQueue.main.async { [weak self] in
                self?.checkDevState()
            }
        }
    }
    
    private func checkDevState() {
        if let dev = STAccessoryManager.share().connectedAccessory.filter({$0.serialNumber == devIdentifier }).first, dev.isConnected == true {
            STLog.info("dev enable")
            labStreamInfo.text = "Device Connected"
        } else {
            alertDevDisConnected()
            labStreamInfo.text = "Device disconnectd"
        }
    }
    
    private func alertDevDisConnected() {
        let alert = UIAlertController(title: "提示", message: "设备连接端口", preferredStyle: .alert)
        let sure = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        
        let cancle = UIAlertAction(title: "知道了", style: .cancel) { _ in
        }
        
        alert.addAction(sure)
        alert.addAction(cancle)
        present(alert, animated: true)
    }
}

//MARK: - UI action
extension STDevPlayViewController {
    @objc func uiActionControlBackTaped(_ sender: UITapGestureRecognizer) {
        controlBackView.isHidden = !controlBackView.isHidden
        navigationController?.navigationBar.isHidden = controlBackView.isHidden
    }
    
    @IBAction func uiActionSetStreamFormatter(_ sender: UIButton) {
        STLog.debug()
        guard let devHandler else {
            STLog.err("no device handler")
            return
        }
        
        let cmdTag = devHandler.getNextCmdTag()
        let cmd = STACommandserialization.setStreamFormatter(cmdTag)
        let command = STAccesoryCmdData(tag: cmdTag, data: cmd)

        Task{
            let cmdResult: STAccessoryWorkResult<STAResponse> = await devHandler.sendCommand(command, protocol: nil)
            STLog.debug("set stream formatter result:\(String(describing: cmdResult.workData?.jsonString()))")
        }
    }
    
    @IBAction func uiActionGetDevConfig(_ sender: UIButton) {
        STLog.debug()
        guard let devHandler else {
            STLog.err("no device handler")
            return
        }
        
        let cmdTag = devHandler.getNextCmdTag()
        let cmd = STACommandserialization.getDevConfig(cmdTag)
        let command = STAccesoryCmdData(tag: cmdTag, data: cmd)
        
        Task{
            let cmdResult: STAccessoryWorkResult<STAResponse> = await devHandler.sendCommand(command, protocol: nil)
            STLog.debug("get device config result:\(String(describing: cmdResult.workData?.jsonString()))")
            if let configData = cmdResult.workData?.responseData {
                let devConfig: [STARespDevConfig] = STARespDevConfig.analysisConfigData(configData)
                let devDes = devConfig.map{$0.jsonString()}
                STLog.debug("device config info:\(devDes)")
            }
        }
    }
    
    @IBAction func uiActionOpenStream(_ sender: UIButton) {
        STLog.debug()
        Task {
            let openResult: STAccessoryWorkResult<STAResponse>? = await devHandler?.openSteam(true, protocol: nil)
            STLog.debug("open stream result:\(openResult?.workData?.jsonString())")
        }
    }
    
    @IBAction func uiActionCloseStream(_ sender: UIButton) {
        STLog.debug()
        Task {
            let openResult: STAccessoryWorkResult<STAResponse>? = await devHandler?.openSteam(false, protocol: nil)
            STLog.debug("close stream result:\(openResult?.workData?.jsonString())")
        }
    }
    
    @IBAction func uiActionBtnSaveLog(_ sender: UIButton) {
        STLog.debug()
        sender.isSelected = !sender.isSelected
        sender.setTitle(sender.isSelected ? "Log Writing" : "Log Print", for: .normal)
        STLog.openFileLog(sender.isSelected)
    }
}

//MARK: - STAccessoryManagerDelegate
extension STDevPlayViewController: STAccessoryConnectDelegate {
    func didConnect(device: EAAccessory) {
        checkDevState()
    }
    
    func didDisconnect(device: EAAccessory) {
        if devIdentifier == device.serialNumber { //当前正在错误的设备，需要关闭流
            
        }
        
        checkDevState()
    }
}

//mark: - image receivew
extension STDevPlayViewController: STAccesoryHandlerImageReceiver {
    func didReceiveDeviceImageResponse(_ imgRes: STAResponse) {
        let imgData = imgRes.imageData
        guard imgData.count > 0 else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else {return}
            mjpegUtil.receive(NSData(data: imgData) as Data) { [weak self] (img: UIImage) in
                STLog.debug("receive image to preview:\(img)")
                self?.imgPreView.image = img
            }
            STLog.debug("did receive image data:\(imgData)")
            speedTool.appendCount(imgData.count)
        }
    }
}
