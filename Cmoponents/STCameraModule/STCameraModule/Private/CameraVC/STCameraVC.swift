//
//  STCameraVC.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/12/22.
//

import STAllBase

class STCameraVC: STABaseVC {
    // MARK: - Properties
    let vm = STCameraVM()
    var devIdentifier = ""
    private let disposeBag = DisposeBag()
    private let controlTapSubject = PublishSubject<Void>()
    
    // MARK: - UI Components
    // Navigation Components
    private let btnBack = UIButton(type: .custom).then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_back"), for: .normal)
    }
    
    private let btnColor = UIButton(type: .custom).then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_color"), for: .normal)
    }
    
    private let btnCameraRotate = UIButton(type: .custom).then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_camera_rotate"), for: .normal)
    }
    
    private let btnPhoneRotate = UIButton(type: .custom).then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_phone_rotate"), for: .normal)
    }
    
    private let vTopNav = UIView().then {
        $0.backgroundColor = .c_333333
    }
    
    // Display Components
    private let vDisplayContainer = UIView().then {
        $0.backgroundColor = .c_theme_back
    }
    
    private let previewImageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .c_theme_back
    }
    
    private let imgMedi = UIImageView().then {
        $0.image = UIImage.stImage(name: "ico_mediscope")
    }
    
    // Control Components
    private let vControl = UIView().then {
        $0.backgroundColor = .clear
    }
    
    private let btnStart = UIButton().then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_start_record"), for: .normal)
    }
    
    private let btnPhoto = UIButton().then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_photo"), for: .normal)
    }
    
    private let btnVideo = UIButton().then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_video"), for: .normal)
    }
    
    private let btnAlbum = UIButton().then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_album"), for: .normal)
    }
    
    private let btnFocalPoint = UIButton().then {
        $0.setBackgroundImage(UIImage.stImage(name: "ico_focal_point"), for: .normal)
    }
    
    private let labStreamInfo = UILabel().then {
        $0.textColor = .c_text
        $0.font = .systemFont(ofSize: 12)
        $0.textAlignment = .center
        $0.backgroundColor = .clear
        $0.text = "Waiting..."
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBasicConfig()
        setupUI()
        setupVM()
        bindActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        resetDeviceOrientation()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        vm.viewDidDisappear()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleScreenTouch(touch)
    }
}

// MARK: - Setup Methods
private extension STCameraVC {
    func setupBasicConfig() {
        cyl_navigationBarHidden = true
        vm.devIdentifier = devIdentifier
        vm.initData()
    }
    
    func setupVM() {
        let input = STCameraVM.STCameraInput(
            btnColor: btnColor.rx.tap.asDriver(),
            btnRotateCamera: btnCameraRotate.rx.tap.asDriver(),
            btnRotatePhone: btnPhoneRotate.rx.tap.asDriver(),
            btnStart: btnStart.rx.tap.asDriver(),
            controlTap: controlTapSubject.asDriver(onErrorJustReturn: ()),
            btnPhoto: btnPhoto.rx.tap.asDriver(),
            btnVideo: btnVideo.rx.tap.asDriver()
        )
        
        bindVMOutput(vm.transform(input: input))
    }
}

// MARK: - Binding Methods
private extension STCameraVC {
    func bindActions() {
        btnBack.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    func bindVMOutput(_ output: STCameraVM.STCameraOutput) {
        bindImageDisplay(output)
        bindButtonStates(output)
        bindControlPanel(output)
        bindDeviceState(output)
        bindTopButtons(output)
    }
    
    func bindImageDisplay(_ output: STCameraVM.STCameraOutput) {
        output.displayImage
            .do(onNext: { [weak self] image in
                self?.imgMedi.isHidden = image.size != .zero
            })
            .drive(previewImageView.rx.image)
            .disposed(by: disposeBag)
        
        output.cameraRotation
            .drive(onNext: { [weak self] rotation in
                self?.updatePreviewRotation(degrees: rotation)
            })
            .disposed(by: disposeBag)
    }
    
    func bindButtonStates(_ output: STCameraVM.STCameraOutput) {
        // 绑定拍摄模式到按钮状态
        output.isPhotoMode
            .drive(onNext: { [weak self] isPhotoMode in
                self?.updateShootingMode(isPhotoMode)
            })
            .disposed(by: disposeBag)
        
        // 绑定录制状态到开始/停止按钮图像
        output.isRecording
            .map { UIImage.stImage(name: $0 ? "ico_stop" : "ico_start_record") }
            .drive(btnStart.rx.backgroundImage())
            .disposed(by: disposeBag)
        
        // 绑定按钮状态
        output.buttonState
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                [self.btnPhoto, self.btnVideo].forEach { button in
                    button.isEnabled = state.isEnabled
                    button.alpha = state.alpha
                }
            })
            .disposed(by: disposeBag)
    }
    
    func bindControlPanel(_ output: STCameraVM.STCameraOutput) {
        output.isControlShow
            .drive(onNext: { [weak self] isShow in
                self?.updateControlVisibility(isShow)
            })
            .disposed(by: disposeBag)
        
        output.speedText
            .drive(labStreamInfo.rx.text)
            .disposed(by: disposeBag)
        
        output.capturedPhoto
            .drive(onNext: { [weak self] image in
                self?.savePhotoToAlbum(image)
            })
            .disposed(by: disposeBag)
    }
    
    func bindDeviceState(_ output: STCameraVM.STCameraOutput) {
        output.deviceState
            .drive(onNext: { [weak self] state in
                if case .disconnected = state {
                    self?.showDeviceAlert()
                }
            })
            .disposed(by: disposeBag)
    }
    
    func bindTopButtons(_ output: STCameraVM.STCameraOutput) {
        output.btnColor
            .drive(onNext: { [weak self] in
                self?.handleColorButtonTap()
            })
            .disposed(by: disposeBag)
        
        output.btnRotateCamera
            .drive(onNext: { [weak self] in
                self?.handleCameraRotate()
            })
            .disposed(by: disposeBag)
        
        output.btnRotatePhone
            .drive(onNext: { [weak self] in
                self?.handlePhoneRotate()
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UI Layout Methods
private extension STCameraVC {
    func setupUI() {
        setupDisplayContainer()
        setupTopNavigation()
        setupControlPanel()
    }
    
    func setupDisplayContainer() {
        view.addSubview(vDisplayContainer)
        vDisplayContainer.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        vDisplayContainer.addSubview(previewImageView)
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(imgMedi)
        imgMedi.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(CGSize(width: 185, height: 64))
        }
    }
    
    func setupTopNavigation() {
        view.addSubview(vTopNav)
        vTopNav.addSubview(btnBack)
        
        let stack = UIStackView()
        stack.axis = .horizontal
        vTopNav.addSubview(stack)
        
        let arr = [/*btnColor,*/ btnCameraRotate, btnPhoneRotate]
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
            make.left.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.width.equalTo(30)
            make.bottom.equalToSuperview()
            make.centerY.equalTo(stack)
        }
        
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.left.equalTo(btnBack.snp.right).offset(10)
            make.right.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.bottom.equalToSuperview()
        }
        
        vTopNav.snp.makeConstraints { make in
            make.left.top.right.equalTo(view)
            make.bottom.equalTo(stack)
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
    
    func setupControlPanel() {
        view.insertSubview(vControl, belowSubview: vTopNav)
        vControl.snp.makeConstraints { make in
            make.top.equalTo(vTopNav.snp.bottom)
            make.left.equalTo(view.safeAreaLayoutGuide)
            make.right.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        let arrControl = [btnStart, btnAlbum, btnPhoto, btnVideo, btnFocalPoint]
        arrControl.forEach {
            vControl.addSubview($0)
        }
        
        vControl.addSubview(labStreamInfo)
        labStreamInfo.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(btnPhoto.snp.top).offset(-10)
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
            updateStackHConstraints(stackH, isPortrait: true)
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
    
    private func updateStackHConstraints(_ stackH: UIStackView, isPortrait: Bool) {
        stackH.snp.remakeConstraints { make in
            make.width.lessThanOrEqualToSuperview().offset(-40)
            make.centerX.equalToSuperview()
            make.height.equalTo(40)
            
            if isPortrait {
                make.bottom.equalToSuperview().offset(-20)
            } else {
                make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            }
        }
        
        if let stackSwitch = vControl.subviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.contains(btnPhoto) == true }) {
            stackSwitch.snp.updateConstraints { make in
                make.bottom.equalTo(stackH.snp.top).offset(isPortrait ? -15 : -10)
            }
        }
    }
}

// MARK: - UI Update Methods
private extension STCameraVC {
    func updateControlVisibility(_ isShow: Bool) {
        UIView.animate(withDuration: 0.3) {
            self.vControl.alpha = isShow ? 1.0 : 0.0
            self.vTopNav.alpha = isShow ? 1.0 : 0.0
        }
    }
    
    func updatePreviewRotation(degrees: Int) {
        let radians = CGFloat(degrees) * .pi / 180.0
        
        UIView.animate(withDuration: 0.3) {
            self.previewImageView.transform = CGAffineTransform(rotationAngle: radians)
        }
        
        previewImageView.snp.remakeConstraints { make in
            if degrees == 90 || degrees == 270 {
                make.center.equalToSuperview()
                make.width.equalTo(vDisplayContainer.snp.height)
                make.height.equalTo(vDisplayContainer.snp.width)
            } else {
                make.edges.equalToSuperview()
            }
        }
        
        view.layoutIfNeeded()
    }
    
    func updateShootingMode(_ isPhotoMode: Bool) {
        btnPhoto.setBackgroundImage(
            UIImage.stImage(name: isPhotoMode ? "ico_camera_taped" : "ico_photo"),
            for: .normal
        )
        
        btnVideo.setBackgroundImage(
            UIImage.stImage(name: isPhotoMode ? "ico_video" : "ico_video_taped"),
            for: .normal
        )
    }
}

// MARK: - Touch Handling
private extension STCameraVC {
    func handleScreenTouch(_ touch: UITouch) {
        let location = touch.location(in: view)
        let controlButtons = [btnStart, btnAlbum, btnPhoto, btnVideo, btnFocalPoint]
        let navButtons = [btnBack, btnColor, btnCameraRotate, btnPhoneRotate]
        
        let isInControlButtons = controlButtons.contains { button in
            button.convert(button.bounds, to: view).contains(location)
        }
        
        let isInNavButtons = navButtons.contains { button in
            button.convert(button.bounds, to: view).contains(location)
        }
        
        if !isInControlButtons && !isInNavButtons {
            controlTapSubject.onNext(())
        }
    }
}

// MARK: - Device Orientation
private extension STCameraVC {
    func resetDeviceOrientation() {
        if #available(iOS 16.0, *) {
            resetOrientationIOS16()
        } else {
            resetOrientationLegacy()
        }
        
        // 强制等待一小段时间确保方向更新完成
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIViewController.attemptRotationToDeviceOrientation()
        }
    }
    
    @available(iOS 16.0, *)
    func resetOrientationIOS16() {
        if let windowScene = view.window?.windowScene {
            let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
            windowScene.requestGeometryUpdate(geometryPreferences) { error in
                STLog.err("Failed to update orientation: \(error)")
            }
        }
    }
    
    func resetOrientationLegacy() {
        if UIDevice.current.orientation != .portrait {
            UIDevice.current.setValue(UIDeviceOrientation.portrait.rawValue, forKey: "orientation")
        }
    }
}

// MARK: - Alert Methods
private extension STCameraVC {
    func showDeviceAlert() {
        let alert = UIAlertController(
            title: "提示",
            message: "设备连接断开",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "知道了", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - UI Actions
private extension STCameraVC {
    func handleColorButtonTap() {
        STLog.debug("颜色按钮点击")
        // 滤镜切换由 VM 处理
    }
    
    func handleCameraRotate() {
        STLog.debug("相机旋转")
        // 实际的相机旋转逻辑由 VM 处理
    }
    
    func handlePhoneRotate() {
        STLog.debug("手机旋转")
        
        if #available(iOS 16.0, *) {
            guard let windowScene = view.window?.windowScene else { return }
            
            let currentOrientation = windowScene.interfaceOrientation
            let geometryPreferences: UIWindowScene.GeometryPreferences
            let isPortrait: Bool
            
            switch currentOrientation {
            case .portrait:
                geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscapeRight)
                isPortrait = false
            case .landscapeRight:
                geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                isPortrait = true
            default:
                geometryPreferences = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .portrait)
                isPortrait = true
            }
            
            windowScene.requestGeometryUpdate(geometryPreferences)
            
            // 更新底部按钮布局
            if let stackH = vControl.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
                updateStackHConstraints(stackH, isPortrait: isPortrait)
            }
            
        } else {
            let currentOrientation = UIDevice.current.orientation
            let newOrientation: UIDeviceOrientation
            let isPortrait: Bool
            
            switch currentOrientation {
            case .portrait:
                newOrientation = .landscapeRight
                isPortrait = false
            case .landscapeRight:
                newOrientation = .portrait
                isPortrait = true
            default:
                newOrientation = .portrait
                isPortrait = true
            }
            
            UIDevice.current.setValue(newOrientation.rawValue, forKey: "orientation")
            
            // 更新底部按钮布局
            if let stackH = vControl.subviews.first(where: { $0 is UIStackView }) as? UIStackView {
                updateStackHConstraints(stackH, isPortrait: isPortrait)
            }
        }
        
        UIViewController.attemptRotationToDeviceOrientation()
    }
}
