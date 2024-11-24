//
//  ViewController.swift
//  STLog_Example
//
//  Created by coder on 2024/11/17.
//

import UIKit
import STLog
import Combine

class ViewController: UIViewController {
    private var timer: Cancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        initData()
    }
    
    private func initData() {
        let publisher = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
            .sink { _ in
                STLog.debug("date:\(STLog.dateStr())")
            }
        timer = publisher
    }
}

