//
//  STAResponseDefine.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/21.
//

import Foundation

protocol STASerialResultDelegate {
    func didAnalysisOnePackage(resArr: [STAResponse])
}

protocol STAResponseSeriaLizerProtocol: NSObjectProtocol {
    var delegate: (NSObject & STASerialResultDelegate)? {set get}
    func shouldAnalysisBuffer(buffer: Data)
}

