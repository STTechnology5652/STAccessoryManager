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
    
    @IBOutlet weak var controlBackView: UIView!
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
    }
    
    private func initData() {
        Task { [weak self] in
            guard let self else {
                return
            }
            
            let manager = STAccessoryManager.share()
            manager.config(delegate: self)
            devHandler = await manager.accessoryHander(devSerialNumber: devIdentifier)
            
            DispatchQueue.main.async { [weak self] in
                self?.checkDevState()
            }
        }
    }
    
    private func checkDevState() {
        if let dev = STAccessoryManager.share().connectedAccessory.filter({$0.serialNumber == devIdentifier }).first, dev.isConnected == true {
            STLog.info("dev enable")
        } else {
            alertDevDisConnected()
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
        guard let devHandler else {
            STLog.err("no device handler")
            return
        }
        
        let cmdTag = devHandler.getNextCmdTag()
        let cmd = STACommandserialization.getDevConfig(cmdTag)
        let command = STAccesoryCmdData(tag: cmdTag, data: cmd)
        devHandler.sendCommand(command, protocol: nil)
    }

    @IBAction func uiActionOpenStream(_ sender: UIButton) {
        STLog.debug()
        Task {
            await devHandler?.openSteam(true, protocol: nil)
        }
    }
    
    @IBAction func uiActionCloseStream(_ sender: UIButton) {
        STLog.debug()
        Task {
            await devHandler?.openSteam(false, protocol: nil)
        }
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
