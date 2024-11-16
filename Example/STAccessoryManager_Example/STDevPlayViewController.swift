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
    
    private var curDev: EAAccessory?
    
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
        STAccessoryManager.share().config(delegate: self)
        checkDevState()
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
    @IBAction func uiActionOpenStream(_ sender: UIButton) {
        STLog.debug()
    }
    
    @IBAction func uiActionCloseStream(_ sender: UIButton) {
        STLog.debug()
    }
}

//MARK: - STAccessoryManagerDelegate
extension STDevPlayViewController: STAccessoryManagerDelegate {
    func didConnect(device: EAAccessory) {
        checkDevState()
    }
    
    func didDisconnect(device: EAAccessory) {
        if let curDev, curDev.serialNumber == device.serialNumber { //当前正在错误的设备，需要关闭流
            
        }
        
        checkDevState()
        
    }
}
