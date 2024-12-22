//
//  STCameraVC+VideoPhoto.swift
//  STCameraModule
//
//  Created by stephenchen on 2024/12/23.
//

import Foundation
import Photos
import STAllBase

extension STCameraVC {
    func savePhotoToAlbum(_ image: UIImage) {
        let rotatedImage = adjustImageOrientation(image)
        requestPhotoLibraryAccess { [weak self] in
            self?.saveImage(rotatedImage)
        }
    }
    
    private func requestPhotoLibraryAccess(completion: @escaping () -> Void) {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                if status == .authorized {
                    completion()
                } else {
                    self?.showPhotoLibraryAlert()
                }
            }
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
        
        let orientation: UIImage.Orientation = {
            switch currentRotation {
            case 90: return .right
            case 180: return .down
            case 270: return .left
            default: return .up
            }
        }()
        
        guard let cgImage = image.cgImage,
              image.imageOrientation != orientation else { return image }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation)
    }
}

// MARK: - Alerts & Toasts
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
    }
    
    func showSaveFailureToast(_ error: String?) {
        STLog.err("照片保存失败: \(error ?? "unknown error")")
    }
}
