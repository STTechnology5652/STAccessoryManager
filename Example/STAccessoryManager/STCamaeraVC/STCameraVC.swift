//
//  STCameraVC.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/12/22.
//

import STAllBase

class STCameraVC: STABaseVC {
    lazy var btnBack = {
        UIButton(type: .custom).then { btn in
            btn.setBackgroundImage(UIImage.stImage(name: "ico_back"), for: .normal)
        }
    }()
    
    lazy var btnColor = {
        UIButton(type: .custom).then { btn in
            btn.setBackgroundImage(UIImage.stImage(name: "ico_color"), for: .normal)
        }
    }()
    
    lazy var btnCameraRotate = {
        UIButton(type: .custom).then { btn in
            btn.setBackgroundImage(UIImage.stImage(name: "ico_camera_rotate"), for: .normal)
        }
    }()
    
    lazy var btnPhoneRotate = {
        UIButton(type: .custom).then { btn in
            btn.setBackgroundImage(UIImage.stImage(name: "ico_phone_rotate"), for: .normal)
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        cyl_navigationBarHidden = true
        
        setUpUI()
    }
    
    private func setUpUI() {
        let topView = UIView()
        view.addSubview(topView)
        let stack = UIStackView()
        topView.addSubview(stack)
        [btnBack, btnColor, btnCameraRotate, btnPhoneRotate].forEach {
            stack.addArrangedSubview($0)
        }

        topView.snp.makeConstraints { make in
            make.left.top.right.equalTo(view)
            make.height.equalTo(view.safeAreaInsets.top + stNavHeihgt)
        }
        
        stack.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: view.safeAreaInsets.top, left: 0, bottom: 0, right: 0))
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
