//
//  DataLoadController.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import UIKit

public protocol DataLoadType: AnyObject {
    func loadingView() -> UIView
    func startLoadingAnimation(_ message: String?)
    func stopLoadingAnimation()
    func layoutLoadingView(_ loadView: UIView, on superView: UIView)
    
    func emptyDataView(message: String, action: @escaping ()->Void) -> UIView
    func layoutEmptyDataView(_ emptyDataView: UIView, on superView: UIView)
    
    func networkView(message: String, action: @escaping ()->Void) -> UIView
    func layoutNetworkView(_ networkView: UIView, on superView: UIView)
}

public class DefaultDataLoad: DataLoadType {
    public func loadingView() -> UIView {
        return activityView
    }
    
    public func startLoadingAnimation(_ message: String?) {
        activityView.startAnimating()
    }
    
    public func stopLoadingAnimation() {
        activityView.stopAnimating()
    }
    
    public func layoutLoadingView(_ loadView: UIView, on superView: UIView) {
        let superSize = superView.frame.size
        loadView.center = CGPoint(x: superSize.width/2.0, y: superSize.height/2.0)
    }
    
    private lazy var activityView: UIActivityIndicatorView = {
        let activityView = UIActivityIndicatorView(style: .medium)
        activityView.hidesWhenStopped = true
        activityView.color = .gray
        return activityView
    }()
    
    public func emptyDataView(message: String, action: @escaping ()->Void) -> UIView {
        let emptyView = LoadErrorView()
        emptyView.message = message
        emptyView.action = action
        return emptyView
    }
    
    public func layoutEmptyDataView(_ emptyDataView: UIView, on superView: UIView) {
        emptyDataView.translatesAutoresizingMaskIntoConstraints = false
        emptyDataView.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        emptyDataView.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
        emptyDataView.leftAnchor.constraint(equalTo: superView.leftAnchor).isActive = true
        emptyDataView.rightAnchor.constraint(equalTo: superView.rightAnchor).isActive = true
    }
    
    public func networkView(message: String, action: @escaping ()->Void) -> UIView {
        let emptyView = LoadErrorView()
        emptyView.message = message
        emptyView.action = action
        return emptyView
    }
    
    public func layoutNetworkView(_ networkView: UIView, on superView: UIView) {
        networkView.translatesAutoresizingMaskIntoConstraints = false
        networkView.topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        networkView.bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
        networkView.leftAnchor.constraint(equalTo: superView.leftAnchor).isActive = true
        networkView.rightAnchor.constraint(equalTo: superView.rightAnchor).isActive = true
    }
}

public protocol DataLoadControllerDelegate: NSObjectProtocol {
    func dataLoadContainerView() -> UIView  //目标视图
    func dataLoadConstraintsView() -> UIView? //相对约束视图
    func networkErrorActionInDataLoadController()
    func emptyDataActionInDataLoadController()
}

public class DataLoadController {
    
    private weak var delegate: DataLoadControllerDelegate!
    private var dataLoadType: DataLoadType
    
    private var loadingView: UIView?
    private var networkView: UIView?
    private var emptyDataView: UIView?
    
    public init(delegate: DataLoadControllerDelegate, dataLoadType: DataLoadType) {
        self.delegate = delegate
        self.dataLoadType = dataLoadType
    }
    
    public func showLoadingView(_ animated: Bool, message: String?) {
        let theLoadingView = dataLoadType.loadingView()
        loadingView = theLoadingView
        let containerView = containerView()
        containerView.addSubview(theLoadingView)
        dataLoadType.layoutLoadingView(theLoadingView, on: containerView)
        if animated {
            dataLoadType.startLoadingAnimation(message)
        }
    }
    
    public func hideLoadingView() {
        guard let theLoadingView = loadingView else {
            return
        }
        
        if theLoadingView.superview != nil {
            dataLoadType.stopLoadingAnimation()
            loadingView?.removeFromSuperview()
        }
        
        loadingView = nil
    }
    
    public func showNetworkErrorView(_ message: String) {
        let errorView = dataLoadType.networkView(message: message) { [weak self] in
            self?.delegate.networkErrorActionInDataLoadController()
        }
        networkView = errorView
        let containerView = containerView()
        containerView.addSubview(errorView)
        if let constraintView = constraintView() {
            dataLoadType.layoutNetworkView(errorView, on: constraintView)
        } else {
            dataLoadType.layoutNetworkView(errorView, on: containerView)
        }
        
    }
    
    public func hideNetworkErrorView() {
        guard let errorView = networkView else {
            return
        }
        errorView.removeFromSuperview()
        networkView = nil
    }
    
    public func showEmptyDataView(_ message: String) {
        let emptyView = dataLoadType.emptyDataView(message: message) { [weak self] in
            self?.delegate.emptyDataActionInDataLoadController()
        }
        emptyDataView = emptyView
        let containerView = containerView()
        containerView.addSubview(emptyView)
        if let constraintView = constraintView() {
            dataLoadType.layoutEmptyDataView(emptyView, on: constraintView)
        } else {
            dataLoadType.layoutEmptyDataView(emptyView, on: containerView)
        }
    }
    
    public func hideEmptyDataView() {
        guard let dataView = emptyDataView else {
            return
        }
        
        dataView.removeFromSuperview()
        emptyDataView = nil
    }
    
    // MARK: - Private
    private func containerView() -> UIView {
        return delegate.dataLoadContainerView()
    }
    
    private func constraintView() -> UIView? {
        return delegate.dataLoadConstraintsView()
    }
}

private class LoadErrorView: UIView {
    private let buttonHeight = 36.0
    
    var message: String? {
        didSet {
            textLabel.text = message
        }
    }
    
    var action: (()->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initUI()
    }
    
    private func initUI() {
        addSubview(textLabel)
        addSubview(button)
        let space = 20.0
        textLabel.leftAnchor.constraint(equalTo: self.leftAnchor, constant: space).isActive = true
        textLabel.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -space).isActive = true
        textLabel.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        button.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: space).isActive = true
        button.widthAnchor.constraint(equalToConstant: 130)
        button.heightAnchor.constraint(equalToConstant: buttonHeight)
        button.centerXAnchor.constraint(equalTo: self.centerXAnchor)
    }
    
    @objc private func clicked() {
        action?()
    }
    
    lazy var textLabel: UILabel = {
        let aLabel = UILabel()
        aLabel.numberOfLines = 0
        aLabel.textAlignment = .center
        aLabel.backgroundColor = .clear
        aLabel.textColor = UIColor.gray
        aLabel.font = UIFont.systemFont(ofSize: 12.0)
        aLabel.translatesAutoresizingMaskIntoConstraints = false
        return aLabel
    }()
    
    lazy var button: UIButton = {
        let aButton = UIButton(type: .custom)
        aButton.backgroundColor = UIColor.white
        aButton.addTarget(self, action: #selector(clicked), for: .touchUpInside)
        aButton.setTitle("点击刷新", for: .normal)
        aButton.setTitleColor(.blue, for: .normal)
        aButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14.0)
        aButton.layer.borderWidth = 1.0
        aButton.layer.borderColor = UIColor.blue.cgColor
        aButton.layer.cornerRadius = buttonHeight/2.0
        aButton.translatesAutoresizingMaskIntoConstraints = false
        return aButton
    }()
}
