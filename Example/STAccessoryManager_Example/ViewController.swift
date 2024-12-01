//
//  ViewController.swift
//  STAccessoryManager_Example
//
//  Created by coder on 2024/11/15.
//

import UIKit
import STAccessoryManager

class ViewController: UIViewController {
    
    private let cellIdentifier = "AccessoryCell"
    private var devList = [EAAccessory]()

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        initData()
    }
    
    private func setUpUI() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func initData() {
        STAccessoryManager.share().config(delegate: self)
        checktDevList()
    }
    
    private func checktDevList() {
        devList = STAccessoryManager.share().connectedAccessory
        tableView.reloadData()
        statusLabel.isHidden = devList.count > 0
    }
}

extension ViewController: STAccessoryConnectDelegate {
    func didConnect(device: EAAccessory) {
        checktDevList()
    }
    
    func didDisconnect(device: EAAccessory) {
        checktDevList()
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell!
        if let cellIns = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = cellIns
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
        }
        
        let dev = devList[indexPath.row]
        cell.textLabel?.text = dev.name
        cell.detailTextLabel?.text = dev.serialNumber
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if devList.count > indexPath.row {
            let dev = devList[indexPath.row] 
            let vc = STDevPlayViewController()
            vc.devIdentifier = dev.serialNumber
            navigationController?.pushViewController(vc, animated: true)
        } else {
            STLog.err("数组越界，未跳转")
        }
    }
}

