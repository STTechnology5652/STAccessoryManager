//
//  STCameraVC.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/12/22.
//

import STAllBase

class STCameraVC: STABaseVC {
    let vm = STCameraVM()
    var devIdentifier = ""
    
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
    
    lazy var vTopNav = {
        UIView().then { v in
            v.backgroundColor = .c_333333
        }
    }()
    
    lazy var vDisplayContainer = {
        UIView().then { v in
            v.backgroundColor = .c_theme_back
        }
    }()
    
    lazy var imgMedi = {
        UIImageView().then { v in
            v.image = UIImage.stImage(name: "ico_mediscope")
        }
    }()
    
    
    lazy var vControl = {
        UIView().then { v in
            v.backgroundColor = .clear
        }
    }()
    
    lazy var btnStart = {
        UIButton().then { v in
            v.setBackgroundImage(UIImage.stImage(name: "ico_start_record"), for: .normal)
        }
    }()
    
    lazy var btnPhoto = {
        UIButton().then { v in
            v.setBackgroundImage(UIImage.stImage(name: "ico_photo"), for: .normal)
        }
    }()
    
    lazy var btnVideo = {
        UIButton().then { v in
            v.setBackgroundImage(UIImage.stImage(name: "ico_video"), for: .normal)
        }
    }()
    
    
    lazy var btnAlbum = {
        UIButton().then { v in
            v.setBackgroundImage(UIImage.stImage(name: "ico_album"), for: .normal)
        }
    }()
    
    lazy var btnFocalPoint = {
        UIButton().then { v in
            v.setBackgroundImage(UIImage.stImage(name: "ico_focal_point"), for: .normal)
        }
    }()

    private let disposeBag = DisposeBag()
    
    // 添加一个 Subject 用于发送点击事件
    private let controlTapSubject = PublishSubject<Void>()
    
    // 添加预览 ImageView
    private lazy var previewImageView = {
        UIImageView().then { iv in
            iv.contentMode = .scaleAspectFit
            iv.backgroundColor = .c_theme_back
        }
    }()
    
    // 添加显示速度的 label
    private lazy var labStreamInfo: UILabel = {
        UILabel().then { label in
            label.textColor = .c_text
            label.font = .systemFont(ofSize: 12)
            label.textAlignment = .center
            label.backgroundColor = .clear
            label.text = "Waiting..."
        }
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cyl_navigationBarHidden = true
        
        setUpUI()
        
        vm.devIdentifier = devIdentifier
        vm.initData()
        bindVM()
        bindActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if #available(iOS 16.0, *) {
            if let windowScene = view.window?.windowScene {
                // 强制恢复为竖直方向
                let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                windowScene.requestGeometryUpdate(geometryPreferences) { error in
                    // error 已经是非可选类型，直接使用
                    STLog.err("Failed to update orientation: \(error)")
                }
            }
        } else {
            // 旧版本的处理方式
            if UIDevice.current.orientation != .portrait {
                UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
                // 添加延迟确保方向更新完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIViewController.attemptRotationToDeviceOrientation()
                }
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // 再次确认设备方向
        if UIDevice.current.orientation != .portrait {
            if #available(iOS 16.0, *) {
                if let windowScene = view.window?.windowScene {
                    let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                    windowScene.requestGeometryUpdate(geometryPreferences)
                }
            } else {
                UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
            }
            UIViewController.attemptRotationToDeviceOrientation()
        }
        
        // VM 清理放在这里
        vm.viewDidDisappear()
    }
    
    private func bindActions() {
        btnBack.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func bindVM() {
        let input = STCameraVM.STCameraInput(
            btnColor: btnColor.rx.tap.asDriver(),
            btnRotateCamera: btnCameraRotate.rx.tap.asDriver(),
            btnRotatePhone: btnPhoneRotate.rx.tap.asDriver(),
            btnStart: btnStart.rx.tap.asDriver(),
            controlTap: controlTapSubject.asDriver(onErrorJustReturn: ()),
            btnPhoto: btnPhoto.rx.tap.asDriver(),
            btnVideo: btnVideo.rx.tap.asDriver()
        )
        let outPut = vm.transform(input: input)
        
        // 绑定显示图像（Driver 已经确保在主线程执行）
        outPut.displayImage
            .do(onNext: { [weak self] image in
                self?.imgMedi.isHidden = image.size != .zero
            })
            .drive(previewImageView.rx.image)
            .disposed(by: disposeBag)
        
        // 绑定拍摄模式到按钮状态
        outPut.isPhotoMode
            .drive(onNext: { [weak self] isPhotoMode in
                self?.updateShootingMode(isPhotoMode)
            })
            .disposed(by: disposeBag)
        
        // 绑定控制面板显示状态
        outPut.isControlShow
            .drive(onNext: { [weak self] isShow in
                self?.updateControlVisibility(isShow)
            })
            .disposed(by: disposeBag)
        
        // 绑定录制状态到开始/停止按钮图像
        outPut.isRecording
            .map { UIImage.stImage(name: $0 ? "ico_stop" : "ico_start_record") }
            .drive(btnStart.rx.backgroundImage())
            .disposed(by: disposeBag)
        
        // 绑定录制状态到照片和视频按钮
        let controlButtons = [btnPhoto, btnVideo]
        controlButtons.forEach { button in
            outPut.isRecording
                .map { !$0 }
                .drive(button.rx.isEnabled)
                .disposed(by: disposeBag)
            
            outPut.isRecording
                .map { $0 ? 0.5 : 1.0 }
                .drive(button.rx.alpha)
                .disposed(by: disposeBag)
        }
        
        outPut.btnColor
            .drive(onNext: { [weak self] in
                self?.handleColorButtonTap()
            })
            .disposed(by: disposeBag)
        
        outPut.btnRotateCamera
            .drive(onNext: { [weak self] in
                self?.handleCameraRotate()
            })
            .disposed(by: disposeBag)
        
        outPut.btnRotatePhone
            .drive(onNext: { [weak self] in
                self?.handlePhoneRotate()
            })
            .disposed(by: disposeBag)
        
        // 绑定相机旋转角度
        outPut.cameraRotation
            .drive(onNext: { [weak self] rotation in
                self?.updatePreviewRotation(degrees: rotation)
            })
            .disposed(by: disposeBag)
        
        // 绑定速度文本（Driver 已经确保在主线程执行）
        outPut.speedText
            .drive(labStreamInfo.rx.text)
            .disposed(by: disposeBag)
        
        // 绑定设备状态
        outPut.deviceState
            .drive(onNext: { [weak self] state in
                switch state {
                case .disconnected:
                    self?.showDeviceAlert()
                case .connected:
                    break
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setUpUI() {
        // 1. 先添加显示容器
        view.addSubview(vDisplayContainer)
        vDisplayContainer.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        // 添加预览 ImageView 到显示容器
        vDisplayContainer.addSubview(previewImageView)
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // 2. 添加 Mediscope 图标
        view.addSubview(imgMedi)
        imgMedi.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 185, height: 64))
        }
        
        // 3. 添加控制面板，确保在显示容器之上
        view.addSubview(vControl)
        vControl.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: stSafeTop, left: 0, bottom: stSafeBottom, right: 0))
        }
        
        // 4. 最后添加顶部导航栏，确保在最上层
        view.addSubview(vTopNav)
        vTopNav.addSubview(btnBack)
        
        let stack = UIStackView()
        stack.axis = .horizontal
        vTopNav.addSubview(stack)
        
        let arr = [/*btnColor, */btnCameraRotate, btnPhoneRotate]
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
        
        btnBack.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.width.equalTo(30)
            make.bottom.equalToSuperview()
            make.centerY.equalTo(stack)
        }
        
        stack.snp.makeConstraints { make in
            make.top.equalTo(stSafeTop)
            make.left.equalTo(btnBack.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview()
        }
        
        vTopNav.snp.makeConstraints { make in
            make.left.top.right.equalTo(view)
            make.height.equalTo(stSafeTop + stNavHeihgt)
        }
        
        if btnContainerArr.count > 1, let firstV = btnContainerArr.first {
            btnContainerArr.remove(at: 0)
            btnContainerArr.forEach { v in
                v.snp.makeConstraints { make in
                    make.width.equalTo(firstV)
                }
            }
        }
        
        setUpControl()
    }
    
    private func setUpControl(){
        let arrControl = [btnStart, btnAlbum, btnPhoto, btnVideo, btnFocalPoint]
        arrControl.forEach {
            vControl.addSubview($0)
        }
        
        // 添加速度显示 label 到 vControl
        vControl.addSubview(labStreamInfo)
        labStreamInfo.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(btnPhoto.snp.top).offset(-10)  // 放在照片按钮上方
            make.height.equalTo(20)
            make.width.equalTo(200)
        }
        
        let stackH = UIStackView()
        stackH.axis = .horizontal
        stackH.spacing = 30
        vControl.addSubview(stackH)
        
        let btnControlArr = [btnAlbum, btnStart, btnFocalPoint]
        btnControlArr.forEach {
            stackH.addArrangedSubview($0)
            $0.snp.makeConstraints { make in
                make.size.equalTo(CGSize(width: 40, height: 40))
            }
        }
        
        stackH.snp.makeConstraints { make in
            make.width.lessThanOrEqualToSuperview().offset(-40)
            make.bottom.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
        }
        
        let stackSwitch = UIStackView()
        vControl.addSubview(stackSwitch)
        stackSwitch.axis = .horizontal
        stackSwitch.spacing = 10
        stackSwitch.addArrangedSubview(btnPhoto)
        stackSwitch.addArrangedSubview(btnVideo)
        stackSwitch.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.bottom.equalTo(stackH.snp.top).offset(-15)
            make.centerX.equalTo(stackH)
        }
    }
    
    private func updateControlVisibility(_ isShow: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.vControl.alpha = isShow ? 1.0 : 0.0
            self.vTopNav.alpha = isShow ? 1.0 : 0.0
        }
    }
    
    // 重写 touchesBegan 方法
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: view)
        
        // 检查点击位置是否在控制面板的子视图或导航栏的子视图内
        let isInControlButtons = [btnStart, btnAlbum, btnPhoto, btnVideo, btnFocalPoint].contains { button in
            let buttonFrame = button.convert(button.bounds, to: view)
            return buttonFrame.contains(location)
        }
        
        let isInNavButtons = [btnBack, btnColor, btnCameraRotate, btnPhoneRotate].contains { button in
            let buttonFrame = button.convert(button.bounds, to: view)
            return buttonFrame.contains(location)
        }
        
        // 如果点击不在任何按钮上，触发显示/隐藏
        if !isInControlButtons && !isInNavButtons {
            controlTapSubject.onNext(())
        }
    }
    
    private func updatePreviewRotation(degrees: Int) {
        // 将角度转换为弧度
        let radians = CGFloat(degrees) * .pi / 180.0
        
        // 使用动画旋转预览视图
        UIView.animate(withDuration: 0.3) {
            self.previewImageView.transform = CGAffineTransform(rotationAngle: radians)
        }
        
        // 根据旋转角度调整预览视图的约束
        if degrees == 90 || degrees == 270 {
            // 横向显示时调整约束
            previewImageView.snp.remakeConstraints { make in
                make.center.equalToSuperview()
                // 交换宽高比
                make.width.equalTo(vDisplayContainer.snp.height)
                make.height.equalTo(vDisplayContainer.snp.width)
            }
        } else {
            // 竖向显示时恢复原始约束
            previewImageView.snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        // 强制布局更新
        view.layoutIfNeeded()
    }
    
    private func showDeviceAlert() {
        let alert = UIAlertController(title: "提示", message: "设备连接断开", preferredStyle: .alert)
        
        let sure = UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }
        
        let cancel = UIAlertAction(title: "知道了", style: .cancel)
        
        alert.addAction(sure)
        alert.addAction(cancel)
        
        present(alert, animated: true)
    }
}

// MARK: - UI Actions
extension STCameraVC {
    // 添加处理方法
    private func handleColorButtonTap() {
        STLog.debug("颜色按钮点击")
        // 滤镜切换由 VM 处理
    }
    
    private func handleCameraRotate() {
        STLog.debug("相机旋转")
        // 实际的相机旋转逻辑由 VM 处理
    }
    
    private func handlePhoneRotate() {
        STLog.debug("手机旋转")
        
        if #available(iOS 16.0, *) {
            // 获取当前窗口场景
            guard let windowScene = view.window?.windowScene else { return }
            
            // 确定新的方向
            let currentOrientation = windowScene.interfaceOrientation
            let geometryPreferences: UIWindowScene.GeometryPreferences
            
            switch currentOrientation {
            case .portrait:
                geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
            case .landscapeRight:
                geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            default:
                geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            }
            
            // 请求更新方向
            windowScene.requestGeometryUpdate(geometryPreferences)
            
        } else {
            // 旧版本的处理方式
            let currentOrientation = UIDevice.current.orientation
            let newOrientation: UIDeviceOrientation
            
            switch currentOrientation {
            case .portrait:
                newOrientation = .landscapeRight
            case .landscapeRight:
                newOrientation = .portrait
            default:
                newOrientation = .portrait
            }
            
            UIDevice.current.setValue(newOrientation.rawValue, forKey: "orientation")
        }
        
        // 强制更新方向
        UIViewController.attemptRotationToDeviceOrientation()
    }
    
    private func rotateCamera() {
        // 切换前后摄像头
        // TODO: 调用相机管理类进行摄像头切换
    }
    
    private func rotateDeviceOrientation() {
        
    }
    
    private func updateShootingMode(_ isPhotoMode: Bool) {
        // 更新照片按钮状态
        btnPhoto.setBackgroundImage(
            UIImage.stImage(name: isPhotoMode ? "ico_camera_taped" : "ico_photo"),
            for: .normal
        )
        
        // 更新视频按钮状态
        btnVideo.setBackgroundImage(
            UIImage.stImage(name: isPhotoMode ? "ico_video" : "ico_video_taped"),
            for: .normal
        )
    }
}
