//
//  STDevPlayViewController.swift
//  STAccessoryManager_Example
//
//  Created by stephenchen on 2024/11/16.
//

import UIKit
import STAccessoryManager

class STDevPlayViewController: UIViewController {
    var devIdentifier: String = ""
    private var devHandler: STAccesoryHandlerInterface?
    private var speedTool = STASpeedTool()
    
    @IBOutlet weak var labStreamInfo: UILabel!
    @IBOutlet weak var controlBackView: UIView!
    @IBOutlet weak var btnSaveLog: UIButton!
    
    
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
            let manager = STAccessoryManager.share()
            manager.config(delegate: self)
            devHandler = manager.accessoryHander(devSerialNumber: devIdentifier)
            devHandler?.configImage(receiver: self, protocol: nil)
            
            DispatchQueue.main.async { [weak self] in
                self?.checkDevState()
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
    
    @IBAction func uiActionGetDevConfig(_ sender: UIButton) {
        STLog.debug()
        DispatchQueue.global().async { [weak self] in
            guard let self, let devHandler else {
                STLog.err("no device handler")
                return
            }
            
            let cmdTag = devHandler.getNextCmdTag()
            let cmd = STACommandserialization.getDevConfig(cmdTag)
            let command = STAccesoryCmdData(tag: cmdTag, data: cmd)
            
            let cmdResult: STAccessoryWorkResult<STAResponse> = devHandler.sendCommand(command, protocol: nil)
            STLog.debug("get device config result:\(String(describing: cmdResult.workData?.jsonString()))")
        }
    }
    
    @IBAction func uiActionOpenStream(_ sender: UIButton) {
        STLog.debug()
        DispatchQueue.global().async { [weak self] in
            let openResult: STAccessoryWorkResult<STAResponse>? = self?.devHandler?.openSteam(true, protocol: nil)
            STLog.debug("open stream result:\(String(describing: openResult?.workData?.jsonString()))")
        }
    }
    
    @IBAction func uiActionCloseStream(_ sender: UIButton) {
        STLog.debug()
        DispatchQueue.global().async { [weak self] in
            let openResult: STAccessoryWorkResult<STAResponse>? = self?.devHandler?.openSteam(false, protocol: nil)
            STLog.debug("close stream result:\(String(describing: openResult?.workData?.jsonString()))")
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
        STLog.debug("did receive image:\(imgData)")
        speedTool.appendCount(imgData.count)
    }
}
