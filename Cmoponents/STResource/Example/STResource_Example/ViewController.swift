//
//  ViewController.swift
//  STResource_Example
//
//  Created by coder on 2024/12/21.
//

import UIKit
import STResource

class ViewController: UIViewController {
    @IBOutlet weak var labInfo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labInfo.textColor = UIColor.c_main
        labInfo.text = "STResource Example".stLocalLized

        // Do any additional setup after loading the view.
    }
}

