//
//  STCameraModuleRegisterService.swift
//  STCameraModule
//
//  Created by coder on 2024/12/22.
//
import STModuleServiceSwift

private class STCameraModuleRegisterService: NSObject, STModuleServiceRegisterProtocol {
    static func stModuleServiceRegistAction() {
        //注册服务 NSObject --> NSObjectProtocol   NSObjectProtocol为 swift 协议
//         STModuleService().stRegistModule(STCameraModuleRegisterService.self, protocol: NSObjectProtocol.self, err: nil)
    }
}

// extension STCameraModuleRegisterService: XXXXProtocol {
// static mehtod for XXXXProtocol
//     static func xxxxx() -> xxxxxObjc {
//         return XXXXX()
//     }
// }
