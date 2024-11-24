//
//  STASpeedTool.swift
//  STAccessoryManager
//
//  Created by stephenchen on 2024/11/24.
//

import Foundation
import Combine

public class STASpeedTool {
    private var countPerSec: UInt64 = 0
    private var timer: Cancellable?
    private var displayAction: ((_: String)->Void)?
    
    public init() {}
    
    deinit {
        timer?.cancel()
    }
    
    public func startCaculted(_ action: @escaping ((_ speedDes: String)->Void)) {
        displayAction = action
        timer = Timer.publish(every: 1.0, on: RunLoop.main, in: .common)
            .autoconnect().sink { [weak self] _ in
                self?.timerAction()
            }
    }
    
    public func appendCount(_ count: Int) {
        countPerSec += UInt64(count)
    }
    
    private func timerAction() {
        var cUint = "B"
        var toDisplay: Float = Float(countPerSec)
        countPerSec = 0
        if toDisplay < 1024 { // B
            cUint = "B"
        } else if toDisplay < 1024 * 1024 { // K
            toDisplay = toDisplay / 1024.0
            cUint = "K"
        } else if toDisplay < 1024 * 1024 * 1024 {// M
            toDisplay = toDisplay / 1024.0 / 1024.0
            cUint = "M"
        } else { // G
            toDisplay = toDisplay / 1024.0 / 1024.0 / 1024.0
            cUint = "G"
        }
        
        let des = String(format: "%.2f", toDisplay) + "\t" + cUint
        displayAction?(des)
    }
}
