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
            STLog.debug("open preview:\(req.parameter)")
            let topVC = req.fromVC
            let vc = STCameraVC()
            vc.devIdentifier = (req.parameter as? [String:String])?[STRouterDefine.kRouterPara_devIdentifier] ?? ""
            topVC?.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

