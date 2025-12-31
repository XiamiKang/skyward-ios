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
    private let fileName: String?
    private let pageTitle: String
    private let bundle: Bundle?
    private let url: URL?
    private let urlRequest: URLRequest?
    
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
    
    /// 使用本地 HTML 文件初始化
    /// - Parameters:
    ///   - fileName: 本地 HTML 文件名（无需后缀或带 .html 后缀）
    ///   - title: 页面标题
    ///   - bundle: 文件所在的 Bundle，默认使用主 Bundle
    public convenience init(fileName: String, title: String, bundle: Bundle? = nil) {
        self.init(fileName: fileName, title: title, bundle: bundle, url: nil, urlRequest: nil)
    }
    
    /// 使用 URL 字符串初始化
    /// - Parameters:
    ///   - urlString: 远程 URL 字符串
    ///   - title: 页面标题
    public convenience init(urlString: String, title: String) {
        let url = URL(string: urlString)
        self.init(url: url, title: title)
    }
    
    /// 使用 URL 初始化
    /// - Parameters:
    ///   - url: 远程 URL
    ///   - title: 页面标题
    public convenience init(url: URL?, title: String) {
        self.init(fileName: nil, title: title, bundle: nil, url: url, urlRequest: nil)
    }
    
    /// 使用 URLRequest 初始化（支持自定义请求头等）
    /// - Parameters:
    ///   - urlRequest: URLRequest 对象
    ///   - title: 页面标题
    public convenience init(urlRequest: URLRequest, title: String) {
        self.init(fileName: nil, title: title, bundle: nil, url: nil, urlRequest: urlRequest)
    }
    
    /// 私有主初始化方法
    private init(fileName: String?, title: String, bundle: Bundle?, url: URL?, urlRequest: URLRequest?) {
        self.fileName = fileName
        self.pageTitle = title
        self.bundle = bundle
        self.url = url
        self.urlRequest = urlRequest
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadContent()
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
    
    // MARK: - Content Loading
    private func loadContent() {
        activityIndicator.startAnimating()
        
        if let urlRequest = urlRequest {
            // 使用 URLRequest 加载
            webView.load(urlRequest)
        } else if let url = url {
            // 使用 URL 加载
            let request = URLRequest(url: url)
            webView.load(request)
        } else if let fileName = fileName {
            // 加载本地 HTML 文件
            loadLocalHTML(fileName: fileName)
        } else {
            activityIndicator.stopAnimating()
            showErrorAlert(message: "无法加载内容：未指定文件或URL")
        }
    }
    
    // MARK: - Local HTML Loading
    private func loadLocalHTML(fileName: String) {
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
    
    // MARK: - Public Methods
    
    /// 加载远程 URL
    /// - Parameters:
    ///   - urlString: URL 字符串
    public func loadURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            showErrorAlert(message: "无效的URL: \(urlString)")
            return
        }
        loadURL(url)
    }
    
    /// 加载远程 URL
    /// - Parameter url: URL 对象
    public func loadURL(_ url: URL) {
        activityIndicator.startAnimating()
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    /// 加载 URLRequest（支持自定义请求头、请求方法等）
    /// - Parameter request: URLRequest 对象
    public func loadURLRequest(_ request: URLRequest) {
        activityIndicator.startAnimating()
        webView.load(request)
    }
    
    /// 重新加载当前页面
    public func reload() {
        webView.reload()
    }
    
    /// 返回上一页
    public func goBack() {
        if webView.canGoBack {
            webView.goBack()
        } else if let navigationController = self.navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    /// 前进到下一页
    public func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    /// 加载 HTML 字符串
    public func loadHTMLString(_ htmlString: String, baseURL: URL? = nil) {
        activityIndicator.startAnimating()
        webView.loadHTMLString(htmlString, baseURL: baseURL)
    }
    
    @objc private func refreshButtonTapped() {
        reload()
    }
    
    @objc private func closeButtonTapped() {
        goBack()
    }
    
    // MARK: - Error Handling
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "加载失败",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "重试", style: .default) { [weak self] _ in
            self?.reload()
        })
        alert.addAction(UIAlertAction(title: "关闭", style: .cancel) { [weak self] _ in
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
        
        // 更新导航栏标题为网页标题（可选）
        if let pageTitle = webView.title, !pageTitle.isEmpty {
            titleLabel.text = pageTitle
        }
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showErrorAlert(message: error.localizedDescription)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        showErrorAlert(message: "无法加载页面: \(error.localizedDescription)")
    }
    
    // 处理链接点击
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        // 获取目标 URL
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }
        
        // 处理 tel: 电话链接
        if url.scheme == "tel" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        // 处理 mailto: 邮件链接
        if url.scheme == "mailto" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
}
