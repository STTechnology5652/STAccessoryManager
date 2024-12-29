//
//  STCameraVC+VideoPhoto.swift
//  STCameraModule
//
//  Created by stephenchen on 2024/12/23.
//

import Foundation
import Photos
import STAllBase

// 添加自定义错误类型
enum PhotoSaveError: Error {
    case noPhotoLibraryAccess  // 无相册访问权限
    case saveFailed(String)    // 保存失败
    case imageInvalid          // 图片无效
}

extension STCameraVC {
    func savePhotoToAlbum(_ image: UIImage) {
        let rotatedImage = adjustImageOrientation(image)
        requestPhotoLibraryAccess { [weak self] result in
            switch result {
            case .success:
                self?.saveImage(rotatedImage)
            case .failure(let error):
                self?.handlePhotoSaveError(error)
            }
        }
    }
    
    private func requestPhotoLibraryAccess(completion: @escaping (Result<Void, PhotoSaveError>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    completion(.success(()))
                } else {
                    completion(.failure(.noPhotoLibraryAccess))
                }
            }
        }
    }
    
    private func handlePhotoSaveError(_ error: PhotoSaveError) {
        switch error {
        case .noPhotoLibraryAccess:
            showPhotoLibraryAlert()
        case .saveFailed(let message):
            showSaveFailureToast(message)
        case .imageInvalid:
            showSaveFailureToast("图片无效")
        }
    }
    
    private func saveImage(_ image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    self?.showSaveSuccessToast()
                } else {
                    self?.showSaveFailureToast(error?.localizedDescription)
                }
            }
        }
    }
    
    private func adjustImageOrientation(_ image: UIImage) -> UIImage {
        let currentRotation = vm.getCurrentRotation()
        guard currentRotation != 0 else { return image }
        
        // 获取当前设备方向
        let isPortrait: Bool
        if #available(iOS 16.0, *) {
            isPortrait = view.window?.windowScene?.interfaceOrientation == .portrait
        } else {
            isPortrait = UIDevice.current.orientation == .portrait
        }
        
        // 根据设备方向和相机旋转角度确定最终图片方向
        let orientation: UIImage.Orientation = {
            if isPortrait {
                // 竖屏时的旋转
                switch currentRotation {
                case 90: return .right
                case 180: return .down
                case 270: return .left
                default: return .up
                }
            } else {
                // 横屏时的旋转需要考虑设备方向
                switch currentRotation {
                case 90: return .left
                case 180: return .down
                case 270: return .right
                default: return .up
                }
            }
        }()
        
        guard let cgImage = image.cgImage,
              image.imageOrientation != orientation else { return image }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation)
    }
}

// MARK: - Toast Methods
private extension STCameraVC {
    func showPhotoLibraryAlert() {
        let alert = UIAlertController(
            title: "需要相册权限",
            message: "请在设置中允许访问相册以保存照片",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        present(alert, animated: true)
    }
    
    func showSaveSuccessToast() {
        STLog.debug("照片保存成功")
        // TODO: 添加成功提示 UI
    }
    
    func showSaveFailureToast(_ error: String?) {
        STLog.err("照片保存失败: \(error ?? "unknown error")")
        // TODO: 添加失败提示 UI
    }
}
