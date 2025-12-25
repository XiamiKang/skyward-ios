//
//  ViewController.swift
//  Example
//
//  Created by yifan kang on 2025/11/13.
//

import UIKit
import LoginModule

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            print("111")
            
            self.showLoginVC()
        }
    }

    @objc private func showLoginVC() {
        let loginVC = LaunchViewController()
        // 如果有导航控制器
        navigationController?.pushViewController(loginVC, animated: true)
    }

}

