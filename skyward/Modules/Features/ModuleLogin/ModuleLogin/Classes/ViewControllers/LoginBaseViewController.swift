//
//  BaseViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/12.
//

import UIKit
import SnapKit

public class LoginBaseViewController: UIViewController {
    
    public lazy var navigationView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        
        let closeButton = UIButton()
        closeButton.setImage(LoginModule.image(named: "navigation_back"), for: .normal)
        closeButton.tintColor = .black
        closeButton.addTarget(self, action: #selector(backLastVCClick), for: .touchUpInside)
        view.addSubview(closeButton)
        
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(16)
            make.width.height.equalTo(30)
        }
        
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = defaultBlackColor
        label.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        label.textAlignment = .center
        return label
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        baseSetupUI()
    }
    
    private func baseSetupUI() {
        view.addSubview(navigationView)
        navigationView.addSubview(titleLabel)
        
        navigationView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(54)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    @objc private func backLastVCClick() {
        self.navigationController?.popViewController(animated: true)
    }
}
