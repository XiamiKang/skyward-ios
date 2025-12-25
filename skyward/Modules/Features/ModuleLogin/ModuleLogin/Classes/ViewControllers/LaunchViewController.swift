//
//  ViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//

import UIKit
import SnapKit
import SafariServices
import TXKit
import SWNetwork

open class LaunchViewController: UIViewController {

    private lazy var txLogoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = LoginModule.image(named: "tx_logo")
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private lazy var txBgImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = LoginModule.image(named: "tx_bg_1")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        return iv
    }()
    
    private let protectionView = PresonalInfoProtectionView()
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.navigationBar.isHidden = true
        view.backgroundColor = UIColor.init(hex: "#FECC33")
        
        setUI()
        setupConstraints()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.showProtectionView()
        }
    }
    
    private func setUI() {
        
        protectionView.onUserAgreementTapped = { [weak self] in
            self?.showUserAgreement()
        }
        
        protectionView.onPrivacyPolicyTapped = { [weak self] in
            self?.showPrivacyPolicy()
        }
        
        protectionView.onDisAgreeButtonTapped = { [weak self] in
            self?.showAgreeAgainView()
        }
        
        protectionView.onAgreeButtonTapped = { [weak self] in
            self?.handleAgreeAction()
        }
        
        protectionView.alpha = 0.0
        
        view.addSubview(txBgImageView)
        view.addSubview(txLogoImageView)
        view.addSubview(protectionView)
    }

    private func setupConstraints() {
        txBgImageView.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(ScreenUtil.screenWidth/2)
        }
        
        txLogoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(158)
            make.centerX.equalToSuperview()
            make.height.equalTo(218)
            make.width.equalTo(166)
        }
        
        protectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func showUserAgreement() {
        // 跳转到用户服务协议页面
        let webVC = WebViewController(
            fileName: "UserAgreement",
            title: "用户服务协议"
        )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func showPrivacyPolicy() {
        // 跳转到隐私政策页面
        let webVC = WebViewController(
            fileName: "PrivacyPolicy",
            title: "隐私协议"
        )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
    
    private func handleAgreeAction() {
        // 处理用户同意逻辑
        UserDefaults.standard.set(true, forKey: "hasAgreedToTerms")
        print("用户已同意协议")
        
        let loginVC = LoginViewController()
        
        self.navigationController?.pushViewController(loginVC, animated: true)
    }
    
    private func showAgreeAgainView() {
        let agreeAgainView = AgreeAgainView()
        
        agreeAgainView.onUserAgreementTapped = { [weak self] in
            self?.showUserAgreement()
        }
        
        agreeAgainView.onPrivacyPolicyTapped = { [weak self] in
            self?.showPrivacyPolicy()
        }
        
        agreeAgainView.onAgreeButtonTapped = { [weak self] in
            self?.handleAgreeAction()
        }
        
        agreeAgainView.show()
    }
    
    private func showProtectionView() {
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.protectionView.alpha = 1
        }
    }
}

