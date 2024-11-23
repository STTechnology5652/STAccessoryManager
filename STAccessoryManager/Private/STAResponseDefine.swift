//
//  STAResponseDefine.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

import Foundation

protocol STAResponseSeriaLizerProtocol: NSObjectProtocol {
    func shouldAnalysisBuffer(buffer: Data) -> (resArr: [STAResponse], usedByts: UInt64)
}

