//
//  ProDeviceButtonState.swift
//  Pods
//
//  Created by TXTS on 2026/2/10.
//


import UIKit
import SWKit

enum ProDeviceButtonState {
    case incomplete   //未完成
    case inprogress   //进行中
    case completed    //已完成
}

class ProDeviceBaseControlView: UIView {

    private let collectButton = UIButton(type: .custom)
    private let lineStarButton = UIButton(type: .custom)
    
    // 新增活动指示器
    private let collectActivityIndicator = UIActivityIndicatorView(style: .medium)
    private let lineStarActivityIndicator = UIActivityIndicatorView(style: .medium)
    
    private let lowPowerTitle = UILabel()
    private let lowPowerswitch = UISwitch()
    
    var collectionAction: (() -> Void)?
    var lineStarAction: (() -> Void)?
    
    // 按钮状态
    private var isCollecting: ProDeviceButtonState = .incomplete {
        didSet {
            updateCollectButtonState()
        }
    }
    
    private var isLiningStar: ProDeviceButtonState = .incomplete {
        didSet {
            updateLineStarButtonState()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .white
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 收藏按钮
        collectButton.translatesAutoresizingMaskIntoConstraints = false
        collectButton.setTitle("收藏", for: .normal)
        collectButton.backgroundColor = UIColor(str: "#F2F3F4")
        collectButton.setTitleColor(UIColor(hex: "#C4C7CA"), for: .normal)
        collectButton.layer.cornerRadius = 6
        collectButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        collectButton.addTarget(self, action: #selector(collectionButtonTapped), for: .touchUpInside)
        self.addSubview(collectButton)
        
        // 收藏按钮活动指示器
        collectActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        collectActivityIndicator.hidesWhenStopped = true
        collectActivityIndicator.color = UIColor(hex: "#FE6A00")
        collectButton.addSubview(collectActivityIndicator)
        
        // 对星按钮
        lineStarButton.translatesAutoresizingMaskIntoConstraints = false
        lineStarButton.setTitle("对星", for: .normal)
        lineStarButton.backgroundColor = UIColor(str: "#FE6A00")
        lineStarButton.setTitleColor(.white, for: .normal)
        lineStarButton.layer.cornerRadius = 6
        lineStarButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        lineStarButton.addTarget(self, action: #selector(lineStarButtonTapped), for: .touchUpInside)
        self.addSubview(lineStarButton)
        
        // 对星按钮活动指示器
        lineStarActivityIndicator.translatesAutoresizingMaskIntoConstraints = false
        lineStarActivityIndicator.hidesWhenStopped = true
        lineStarActivityIndicator.color = .white
        lineStarButton.addSubview(lineStarActivityIndicator)
        
        lowPowerTitle.translatesAutoresizingMaskIntoConstraints = false
        lowPowerTitle.text = "低功耗"
        lowPowerTitle.textColor = UIColor(str: "#070808")
        lowPowerTitle.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(lowPowerTitle)
        
        lowPowerswitch.translatesAutoresizingMaskIntoConstraints = false
        lowPowerswitch.onTintColor = UIColor(str: "#16C282")
        lowPowerswitch.addTarget(self, action: #selector(logSwitchChanged), for: .valueChanged)
        self.addSubview(lowPowerswitch)
        
        setConstraint()
    }
    
    private func setConstraint() {
        
        NSLayoutConstraint.activate([
            lineStarButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            lineStarButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            lineStarButton.widthAnchor.constraint(equalToConstant: 135),
            lineStarButton.heightAnchor.constraint(equalToConstant: 48),
            
            collectButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            collectButton.trailingAnchor.constraint(equalTo: lineStarButton.leadingAnchor, constant: -16),
            collectButton.widthAnchor.constraint(equalToConstant: 135),
            collectButton.heightAnchor.constraint(equalToConstant: 48),
            
            lowPowerswitch.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            lowPowerswitch.trailingAnchor.constraint(equalTo: collectButton.leadingAnchor, constant: -16),
            
            lowPowerTitle.topAnchor.constraint(equalTo: lowPowerswitch.bottomAnchor, constant: 5),
            lowPowerTitle.centerXAnchor.constraint(equalTo: lowPowerswitch.centerXAnchor),
        ])
    }
    
    // MARK: - 按钮状态更新
    private func updateCollectButtonState() {
        switch isCollecting {
        case .incomplete:
            collectButton.setTitle("收藏", for: .normal)
            collectButton.isEnabled = false
            collectButton.setTitleColor(UIColor(str: "#C4C7CA"), for: .normal)
            collectActivityIndicator.stopAnimating()
            
            // 重置标题位置
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = .zero
            collectButton.configuration = configuration
        case .inprogress:
            collectButton.setTitle("收藏中", for: .normal)
            collectButton.isEnabled = false
            collectButton.setTitleColor(UIColor(str: "#FE6A00"), for: .normal)
            collectActivityIndicator.startAnimating()
            
            // 调整标题位置
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: 20,
                bottom: 0,
                trailing: 0
            )
            collectButton.configuration = configuration
        case .completed:
            collectButton.setTitle("收藏", for: .normal)
            collectButton.isEnabled = true
            collectButton.setTitleColor(UIColor(str: "#FE6A00"), for: .normal)
            collectActivityIndicator.stopAnimating()
            
            // 重置标题位置
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = .zero
            collectButton.configuration = configuration
        }
    }
    
    private func updateLineStarButtonState() {
        switch isLiningStar {
        case .incomplete:
            lineStarButton.setTitle("对星", for: .normal)
            lineStarButton.isEnabled = true
            lineStarButton.backgroundColor = UIColor(str: "#FE6A00")
            lineStarActivityIndicator.stopAnimating()
            
            // 重置标题位置
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = .zero
            lineStarButton.configuration = configuration
        case .inprogress:
            lineStarButton.setTitle("对星中", for: .normal)
            lineStarButton.isEnabled = false
            lineStarButton.backgroundColor = UIColor(str: "#FE6A00").withAlphaComponent(0.7)
            lineStarActivityIndicator.startAnimating()
            
            // 调整标题位置
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: 20,
                bottom: 0,
                trailing: 0
            )
            lineStarButton.configuration = configuration
        case .completed:
            lineStarButton.setTitle("对星", for: .normal)
            lineStarButton.isEnabled = true
            lineStarButton.backgroundColor = UIColor(str: "#FE6A00")
            lineStarActivityIndicator.stopAnimating()
            
            // 重置标题位置
            var configuration = UIButton.Configuration.plain()
            configuration.contentInsets = .zero
            lineStarButton.configuration = configuration
        }
    }
    
    // MARK: - 公开方法
    func startCollecting() {
        isCollecting = .inprogress
    }
    
    func stopCollecting(with collectedSuccess: Bool) {
        isCollecting = collectedSuccess ? .completed : .incomplete
    }
    
    func startLiningStar() {
        isLiningStar = .inprogress
    }
    
    func stopLiningStar(with lineSuccese: Bool) {
        isLiningStar = lineSuccese ? .completed : .incomplete
    }
    
    @objc private func collectionButtonTapped() {
        print("收藏按钮点击")
        
        // 开始收藏动画
        startCollecting()
        
        // 延迟执行回调，模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.collectionAction?()
        }
    }
    
    @objc private func lineStarButtonTapped() {
        print("对星按钮点击")
        
        // 开始对星动画
        startLiningStar()
        
        // 延迟执行回调，模拟网络请求
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lineStarAction?()
        }
    }
    
    @objc private func logSwitchChanged() {
        WiFiDeviceManager.shared.deepSleep(enable: lowPowerswitch.isOn) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let alignmentResult):
                    print("低功耗指令成功")
                case .failure(let error):
                    print("低功耗指令失败")
                }
            }
        }
    }
}
