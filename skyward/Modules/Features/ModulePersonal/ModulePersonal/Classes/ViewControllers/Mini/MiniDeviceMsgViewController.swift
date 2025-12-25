//
//  MiniDeviceMsgViewController.swift
//  SWKit
//
//  Created by TXTS on 2025/12/15.
//

import UIKit

class MiniDeviceMsgViewController: PersonalBaseViewController {
    
    let noMsgView = UIView()
    let noMsgImageView = UIImageView()
    let noMsgText = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraint()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        customTitle.text = "信息"
        
        noMsgView.backgroundColor = .white
        self.view.addSubview(noMsgView)
        
        noMsgImageView.image = PersonalModule.image(named: "device_mini_noMsg")
        noMsgView.addSubview(noMsgImageView)
        
        noMsgText.text = "暂无消息"
        noMsgText.textColor = UIColor(str: "#74777B")
        noMsgText.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        noMsgView.addSubview(noMsgText)
    }
    
    private func setupConstraint() {
        noMsgView.translatesAutoresizingMaskIntoConstraints = false
        noMsgImageView.translatesAutoresizingMaskIntoConstraints = false
        noMsgText.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            noMsgView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            noMsgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noMsgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noMsgView.heightAnchor.constraint(equalToConstant: 300),
            
            noMsgImageView.centerXAnchor.constraint(equalTo: noMsgView.centerXAnchor),
            noMsgImageView.topAnchor.constraint(equalTo: noMsgView.topAnchor, constant: 20),
            noMsgImageView.widthAnchor.constraint(equalToConstant: 96),
            noMsgImageView.heightAnchor.constraint(equalToConstant: 96),
            
            noMsgText.centerXAnchor.constraint(equalTo: noMsgView.centerXAnchor),
            noMsgText.topAnchor.constraint(equalTo: noMsgImageView.bottomAnchor, constant: 5),
        ])
    }
}
