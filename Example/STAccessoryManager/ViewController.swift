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
    
    lazy var settingBtn = {
        UIButton(type: .custom).then { btn in
            btn.setBackgroundImage(UIImage.stImage(name: "ico_setting"), for: .normal)
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
        
        let icon = UIImageView(image: UIImage.stImage(name: "img_home_back"))
        view.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)

        }
        
        let stack = UIStackView()
        view.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 0.1
        
        stack.addArrangedSubview(tableView)
        stack.addArrangedSubview(labStatus)
        stack.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }

        labStatus.snp.makeConstraints { make in
            make.height.equalTo(100)
        }
        
        view.addSubview(self.settingBtn)
        settingBtn.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.top.equalTo(stNavHeihgt + 10)
            make.width.equalTo(42)
            make.height.equalTo(52)
        }
        settingBtn.addTarget(self, action: #selector(settingAction), for: .touchUpInside)
        
        
#if K_BETA
        stack.addArrangedSubview(btnForceJump)
        btnForceJump.addTarget(self, action: #selector(self.btnActionForceJump(_:)), for: .touchUpInside)
        btnForceJump.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
#endif
    }
    
    @objc func settingAction(){
        let vc = STSettingVC()
        self.navigationController?.pushViewController(vc, animated: true)
        
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
        STRouter.shareInstance().stOpenUrlInstance(STRouterDefine.kCameraModul, fromVC: self)
        
//        let vc = STDevPlayViewController()
//        vc.devIdentifier = ""
//        navigationController?.pushViewController(vc, animated: true)
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
            
            let req = STRouterUrlRequest.instance { re in
                re.fromVC = self
                re.parameter = [STRouterDefine.kRouterPara_devIdentifier: dev.serialNumber]
                re.urlToOpen = STRouterDefine.kCameraModul
            }
            
            stRouterOpenUrlRequest(req) { _ in }
            
//            let vc = STDevPlayViewController()
//            vc.devIdentifier = dev.serialNumber
//            navigationController?.pushViewController(vc, animated: true)
        } else {
            STLog.err("数组越界，未跳转")
        }
    }
}
