//
//  ViewController.swift
//  STAccessoryManager_Example
//
//  Created by coder on 2024/11/15.
//

import UIKit
import STAccessoryManager
import STResource
import STAllBase

class ViewController: STABaseVC {
    
    private let cellIdentifier = "AccessoryCell"
    private var devList = [EAAccessory]()
    
    lazy var labStatus: UILabel = {
        UILabel().then {
            $0.backgroundColor = UIColor.c_main
            $0.textColor = .c_text_warning
            $0.textAlignment = .center
            $0.text = "接入设备才能使用...".stLocalLized
        }
    }()
    
#if K_BETA
    lazy var btnForceJump = {
        UIButton(type: .custom).then {
            $0.backgroundColor = .green
            $0.setTitle("开发-跳转".stLocalLized, for: .normal)
            $0.setTitleColor(.c_text, for: .normal)
        }
    }()
#endif
    
    lazy var tableView = {
        UITableView(frame: .zero, style: .plain).then {
            $0.estimatedRowHeight = 50
            $0.rowHeight = 50
            $0.backgroundColor = UIColor.c_main
            $0.dataSource = self
            $0.delegate = self
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cyl_navigationBarHidden = true
        setUpUI()
        initData()
    }
    
    private func setUpUI() {
        view.backgroundColor = UIColor.c_theme_back
        
        let stack = UIStackView()
        view.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 0.1
        
        // tableView 放的一个view中，然后再放到 stack， 防止tableView的尺寸不正确
        let tableContainer = UIView()
        stack.addArrangedSubview(tableContainer)
        tableContainer.addSubview(tableView)
        
        stack.addArrangedSubview(labStatus)
        stack.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        labStatus.snp.makeConstraints { make in
            make.height.equalTo(100)
            make.top.equalTo(tableView.snp.bottom).offset(self.view.safeAreaInsets.bottom - 10)
        }
        
#if K_BETA
        stack.addArrangedSubview(btnForceJump)
        btnForceJump.addTarget(self, action: #selector(self.btnActionForceJump(_:)), for: .touchUpInside)
        btnForceJump.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
#endif
    }
    
    private func initData() {
        STAccessoryManager.share().config(delegate: self)
        checktDevList()
    }
    
    private func checktDevList() {
        devList = STAccessoryManager.share().connectedAccessory
        tableView.reloadData()
        labStatus.isHidden = devList.count > 0
    }
    
#if K_BETA
    @objc
    private func btnActionForceJump(_ sender: UIButton) {
        let vc = STDevPlayViewController()
        vc.devIdentifier = ""
        navigationController?.pushViewController(vc, animated: true)
    }
#endif
    
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
        if let cellUse: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = cellUse
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellIdentifier)
            cell.selectionStyle = .none
            cell.backgroundColor = .clear
        }
        
        let dev = devList[indexPath.row]
        cell.textLabel?.textColor = .c_text
        cell.textLabel?.text = dev.name
        cell.detailTextLabel?.textColor = .c_text
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
