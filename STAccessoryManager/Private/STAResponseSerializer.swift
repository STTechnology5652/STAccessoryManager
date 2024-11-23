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
    
    func shouldAnalysisBuffer(buffer: Data) -> (resArr: [STAResponse], usedByts: UInt64) {
        STLog.debug("start analysis data: \(buffer)")
        var usedLength: UInt64 = 0
        let responseArr: [STAResponse] = STAResponse.analysisiBuffer(buffer, byteUsed: &usedLength)
        return (responseArr, usedLength)
    }
}

extension STAResponseSeriaLizer {
    
}
