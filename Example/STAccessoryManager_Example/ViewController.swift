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
        let manager = STAccessoryManager.share()
        devList = manager.connectedAccessory
        manager.config(delegate: self)
        tableView.reloadData()
    }
    
    func setUpUI() {
        tableView.delegate = self
        tableView.dataSource = self
    }
}

extension ViewController: STAccessoryManagerDelegate {
    func didConnect(device: EAAccessory) {
        devList = STAccessoryManager.share().connectedAccessory
        tableView.reloadData()
    }
    
    func didDisconnect(device: EAAccessory) {
        devList = STAccessoryManager.share().connectedAccessory
        tableView.reloadData()
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

