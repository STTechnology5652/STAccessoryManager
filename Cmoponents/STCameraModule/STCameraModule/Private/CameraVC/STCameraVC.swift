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
        stack.axis = .horizontal
        topView.addSubview(stack)
        
        stack.addArrangedSubview(btnBack)
        let arr = [ btnColor, btnCameraRotate, btnPhoneRotate]
        var btnContainerArr = [UIView]()
        arr.forEach {
            let v = UIView()
            v.addSubview($0)
            $0.snp.makeConstraints { make in
                make.center.equalToSuperview()
            }
            stack.addArrangedSubview(v)
            btnContainerArr.append(v)
        }
        
        topView.snp.makeConstraints { make in
            make.left.top.right.equalTo(view)
            make.height.equalTo(stSafeTop + stNavHeihgt)
        }
        
        stack.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: stSafeTop, left: 10, bottom: 0, right: 0))
        }
        
        if btnContainerArr.count > 1, let firstV = btnContainerArr.first {
            btnContainerArr.remove(at: 0)
            btnContainerArr.forEach { v in
                v.snp.makeConstraints { make in
                    make.width.equalTo(firstV)
                }
            }
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
