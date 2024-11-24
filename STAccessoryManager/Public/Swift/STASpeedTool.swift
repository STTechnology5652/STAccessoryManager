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
    private var timer: DispatchSourceTimer?
    private var displayAction: ((_: String)->Void)?
    
    public init() {}
    
    deinit {
        timer?.cancel()
    }
    
    public func startCaculted(_ action: @escaping ((_ speedDes: String)->Void)) {
        displayAction = action
        let timer = DispatchSource.makeTimerSource()
        timer.schedule(deadline: DispatchTime.now() + 1, repeating: 1.0, leeway: .nanoseconds(1))
        timer.setEventHandler { [weak self] in
                self?.timerAction()
        }
        self.timer = timer
        timer.activate()
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
        DispatchQueue.main.async { [weak self] in
            self?.displayAction?(des)
        }
    }
}
