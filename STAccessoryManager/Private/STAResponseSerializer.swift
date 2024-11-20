//
//  STAResponseSerializer.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

import Foundation

class STAResponseSeriaLizer: NSObject, STAResponseSeriaLizerProtocol {
    let devSerial: String
    let protocolIdv: String
    init(devSerial: String, protocolIdv: String) {
        self.devSerial = devSerial
        self.protocolIdv = protocolIdv
    }
    
    func shouldAnalysisBuffer(buffer: Data) -> STACmdResponse {
        STLog.debug("start analysis data: \(buffer)")
        return STACmdResponse(success: false)
    }
}

extension STAResponseSeriaLizer {
    
}
