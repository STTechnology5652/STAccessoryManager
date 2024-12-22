//
//  STABaseUI.swift
//  Pod
//
//  Created by coder on 2024/12/21.
//
// @_exported import XXXXXX //这个是为了对外暴露下层依赖的Pod

import CYLTabBarController
import STResource

open class STABaseVC: CYLBaseViewController {
    open override func viewDidLoad() {
        super.viewDidLoad()
        let btn = UIButton(type: .custom)
        btn.setBackgroundImage(UIImage.stImage(name: "ico_back"), for: .normal)
        btn.addTarget(self, action: #selector(self.stNavBackItemAction), for: .touchUpInside)
        let barBack = UIBarButtonItem(customView: btn)
        navigationItem.leftBarButtonItem = barBack
    }
   
    @objc
    private func stNavBackItemAction() {
        navigationController?.popViewController(animated: true)
    }
}
public class STABaseNav: CYLBaseNavigationController {}


