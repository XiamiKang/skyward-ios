//
//  WebViewController.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//


import UIKit
import WebKit

public class WebViewController: LoginBaseViewController {
    
    // MARK: - Properties
    private let fileName: String
    private let pageTitle: String
    private let bundle: Bundle?
    
    // MARK: - UI Components
    private lazy var webView: WKWebView = {
        let webView = WKWebView()
        webView.backgroundColor = .white
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .medium)
        } else {
            indicator = UIActivityIndicatorView(style: .gray)
        }
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    // MARK: - Initialization
    /// 初始化方法，支持传入本地 HTML 文件名
    /// - Parameters:
    ///   - fileName: 本地 HTML 文件名（无需后缀或带 .html 后缀）
    ///   - title: 页面标题
    ///   - bundle: 文件所在的 Bundle，默认使用主 Bundle
    public init(fileName: String, title: String, bundle: Bundle? = nil) {
        self.fileName = fileName
        self.pageTitle = title
        self.bundle = bundle
        super.init(nibName: nil, bundle: nil)
    }
    
    /// 兼容旧的初始化方法，将 URL 字符串视为文件名
    @available(*, deprecated, message: "请使用 init(fileName:title:bundle:) 方法")
    public convenience init(urlString: String, title: String) {
        self.init(fileName: urlString, title: title, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadLocalHTML()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        titleLabel.text = pageTitle
        
        // 添加 WebView
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        // 添加加载指示器
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // WebView 约束
            webView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // 加载指示器约束
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    // MARK: - Local HTML Loading
    private func loadLocalHTML() {
        activityIndicator.startAnimating()
        
        // 获取 Bundle
        let resourceBundle = bundle ?? Bundle.main
        
        // 处理文件名（支持带或不带 .html 后缀）
        var htmlFileName = fileName
        if !htmlFileName.hasSuffix(".html") {
            htmlFileName += ".html"
        }
        
        // 移除 .html 后缀用于获取路径
        let fileNameWithoutExtension = (fileName as NSString).deletingPathExtension
        
        // 尝试不同方式加载文件
        if let filePath = resourceBundle.path(forResource: fileNameWithoutExtension, ofType: "html") {
            // 方式1：直接通过文件路径加载
            let fileURL = URL(fileURLWithPath: filePath)
            let request = URLRequest(url: fileURL)
            webView.load(request)
            
        } else if let fileURL = resourceBundle.url(forResource: fileNameWithoutExtension, withExtension: "html") {
            // 方式2：通过 URL 加载
            let request = URLRequest(url: fileURL)
            webView.load(request)
            
        } else {
            // 方式3：尝试直接使用传入的文件名
            if let directFilePath = resourceBundle.path(forResource: fileName, ofType: nil) {
                let fileURL = URL(fileURLWithPath: directFilePath)
                let request = URLRequest(url: fileURL)
                webView.load(request)
            } else {
                // 所有方式都失败
                activityIndicator.stopAnimating()
                showErrorAlert(message: "找不到文件: \(fileName)")
            }
        }
    }
    
    // MARK: - Helper Methods
    /// 加载 HTML 字符串
    public func loadHTMLString(_ htmlString: String, baseURL: URL? = nil) {
        activityIndicator.startAnimating()
        webView.loadHTMLString(htmlString, baseURL: baseURL)
    }
    
    @objc private func refreshButtonTapped() {
        webView.reload()
    }
    
    @objc private func closeButtonTapped() {
        if let navigationController = self.navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Error Handling
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "加载失败",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default) { [weak self] _ in
            self?.closeButtonTapped()
        })
        present(alert, animated: true)
    }
    
    // MARK: - JavaScript Interaction
    /// 执行 JavaScript 代码
    public func evaluateJavaScript(_ script: String, completion: ((Result<Any?, Error>) -> Void)? = nil) {
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                completion?(.failure(error))
            } else {
                completion?(.success(result))
            }
        }
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        
        // 可以在这里注入 JavaScript 或修改页面内容
        // 例如：修改页面标题为自定义标题
        // webView.evaluateJavaScript("document.title = '\(pageTitle)'")
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showErrorAlert(message: error.localizedDescription)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showErrorAlert(message: "无法加载页面: \(error.localizedDescription)")
    }
    
    // 处理链接点击（可选）
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
           let url = navigationAction.request.url,
           url.scheme?.hasPrefix("http") == true {
            // 如果是 http/https 链接，可以在内部 Safari 或外部浏览器打开
            // UIApplication.shared.open(url, options: [:], completionHandler: nil)
            // decisionHandler(.cancel)
            // return
        }
        decisionHandler(.allow)
    }
}

