//
//  STCameraModuleRegisterRouter.swift
//  STCameraModule
//
//  Created by coder on 2024/12/22.
//

import STComponentTools.STRouter
import STAllBase

private class STCameraModuleRegisterRouter: NSObject, STRouterRegisterProtocol {
    public static func stRouterRegisterExecute() {
        stRouterRegisterUrlParttern(STRouterDefine.kCameraModul, nil) { (req: STRouterUrlRequest, com: STRouterUrlCompletion?) in
            let topVC = req.fromVC
            let vc = STCameraVC()
            topVC?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

