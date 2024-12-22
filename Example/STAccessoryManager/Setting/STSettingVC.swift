//
//  STSettingVC.swift
//  STAccessoryManager_Beta
//
//  Created by zengsong on 2024/12/22.
//

import UIKit
import STAccessoryManager
import STResource
import STAllBase

class STSettingVC: STABaseVC {

    var icon = UIImageView()
    
    var versionLb = UILabel()
    
    var list = ["语言"]
    
    var tableView: UITableView = {
        var tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 50
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.register(UINib(nibName: "STSetItemCell", bundle: nil), forCellReuseIdentifier: String(describing: STSetItemCell.self))
        
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "设置".stLocalLized
        setupUI()
    }
    

    private func setupUI(){
        view.backgroundColor = UIColor.c_theme_back
        self.icon.image = UIImage.stImage(name: "ico_setting")
        self.view.addSubview(self.icon)
        self.icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(stNavHeihgt + 80)
            make.width.height.equalTo(80)
        }
        
        self.versionLb.text = "1.0.0";
        self.versionLb.textColor = .black
        self.versionLb.textAlignment = .center
        self.versionLb.font = UIFont(name: "PingFangSC-Regular", size: 14)
        self.view.addSubview(self.versionLb)
        self.versionLb.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.icon.snp.bottom).offset(20)
            make.height.equalTo(20)
        }
        tableView.delegate = self
        tableView.dataSource = self
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(0)
            make.top.equalTo(self.icon.snp.bottom).offset(100)
        }
    }
}


extension STSettingVC:UITableViewDelegate,UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return list.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: STSetItemCell.self)) as! STSetItemCell
        cell.titLb.text = list[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}
