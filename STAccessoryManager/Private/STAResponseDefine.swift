//
//  STAResponseDefine.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

import Foundation

class STACmdResponse {
    let analysisSuccess: Bool
    let cmdTag: UInt8
    let responseStatus: UInt8
    let responseData: Data
    let reasonseInfo: Any?
    let usedLenght: Int
    
    init(success: Bool, cmdTag: UInt8 = 0x00, responseStatus: UInt8 = 0x00, responseData: Data = Data(), reasonseInfo: Any? = nil, usedLength: Int = 0) {
        self.analysisSuccess = success
        self.cmdTag = cmdTag
        self.responseStatus = responseStatus
        self.responseData = responseData
        self.reasonseInfo = reasonseInfo
        self.usedLenght = usedLength
    }
}

protocol STAResponseSeriaLizerProtocol: NSObjectProtocol {
    func shouldAnalysisBuffer(buffer: Data) -> STACmdResponse
}

