//
//  File.swift
//  ModulePersonal
//
//  Created by TXTS on 2025/12/23.
//

import UIKit
import SWKit

class CancelAccountViewController: PersonalBaseViewController {
    
    private let viewModel = PersonalViewModel()
    
    private let warnImageView = UIImageView()
    private let titleLabel = UILabel()
    private let contentLabel = UILabel()
    private let cancelButton = UIButton()
    private let confirmButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        self.view.backgroundColor = .white
        customTitle.text = "注销账号"
        
        warnImageView.image = PersonalModule.image(named: "default_warning3")
        
        titleLabel.text = "注销后，以下内容会被删除"
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .medium)
        
        contentLabel.text = "兴趣点及路线、绑定的紧急联系人即被删除"
        contentLabel.textColor = UIColor(str: "#84888C")
        contentLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.black, for: .normal)
        cancelButton.backgroundColor = UIColor(str: "#F2F3F4")
        cancelButton.layer.cornerRadius = 8
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        cancelButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        confirmButton.setTitle("继续注销", for: .normal)
        confirmButton.backgroundColor = UIColor(str: "#F7594B")
        confirmButton.layer.cornerRadius = 8
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        
        view.addSubview(warnImageView)
        view.addSubview(titleLabel)
        view.addSubview(contentLabel)
        view.addSubview(cancelButton)
        view.addSubview(confirmButton)
        
        setConstraint()
    }
    
    private func setConstraint() {
        warnImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            warnImageView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 80),
            warnImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            warnImageView.widthAnchor.constraint(equalToConstant: 72),
            warnImageView.heightAnchor.constraint(equalToConstant: 72),
            
            titleLabel.topAnchor.constraint(equalTo: warnImageView.bottomAnchor, constant: 16),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            cancelButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 36),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            cancelButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 48)/2),
            cancelButton.heightAnchor.constraint(equalToConstant: 48),
            
            confirmButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 36),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            confirmButton.widthAnchor.constraint(equalToConstant: (UIScreen.main.bounds.width - 48)/2),
            confirmButton.heightAnchor.constraint(equalToConstant: 48),
        ])
    }
    
    @objc private func confirmButtonTapped() {
        SWAlertView.showAlert(title: "确认注销账号吗？此操作不可恢复", message: "") { [weak self] in
            guard let self = self else { return }
            self.viewModel.cancelAccount()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    if case .failure(_) = completion {
                        self?.view.sw_showWarningToast("注销账号失败")
                    }
                } receiveValue: { [weak self] success in
                    if success {
                        self?.view.sw_showSuccessToast("注销账号成功")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            SWRouter.handle(RouteTable.loginPageUrl)
                        }
                    } else {
                        self?.view.sw_showWarningToast("注销账号失败")
                    }
                }
                .store(in: &self.viewModel.cancellables)
        }
    }
}
