//
//  TxtsBaseViewController.swift
//  txtsPersonal
//
//  Created by TXTS on 2025/11/18.
//

import UIKit
import SWKit

public class PersonalBaseViewController: UIViewController {
    
    // MARK: - UI组件
    let customNavView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(PersonalModule.image(named: "default_back"), for: .normal)
        button.tintColor = .black
        return button
    }()
    
    let customTitle: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        baseSetupUI()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func baseSetupUI() {
        // 添加自定义导航栏
        view.addSubview(customNavView)
        customNavView.addSubview(backButton)
        customNavView.addSubview(customTitle)
        
        NSLayoutConstraint.activate([
            // 自定义导航栏
            customNavView.topAnchor.constraint(equalTo: view.topAnchor),
            customNavView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customNavView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customNavView.heightAnchor.constraint(equalToConstant: 104),
            
            // 返回按钮
            backButton.leadingAnchor.constraint(equalTo: customNavView.leadingAnchor, constant: 16),
            backButton.bottomAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: -12),
            backButton.widthAnchor.constraint(equalToConstant: 24),
            backButton.heightAnchor.constraint(equalToConstant: 24),
            
            customTitle.centerXAnchor.constraint(equalTo: customNavView.centerXAnchor),
            customTitle.bottomAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: -10),
        ])
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
    }
    
    @objc public func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}
