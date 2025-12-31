//
//  TeamInviteMemberViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/1.
//

import UIKit
import SnapKit
import TXKit
import SWKit
import SWTheme
import SWNetwork

class TeamInviteMemberViewController: BaseViewController {
    
    // MARK: - Properties
    
    private var phoneNumbers: [String] = []
    
    private var activeTextFieldIndexPath: IndexPath?
    
    var teamId: String?
    var conversation: Conversation? // 从创建队伍过来的
    
    // MARK: - Initialization
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public init(teamId: String? = nil, conversation: Conversation? = nil) {
        self.teamId = teamId
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        setupTapGestureToDismissKeyboard()
    }
    
    
    // MARK: - Over ride
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func setupViews() {
        super.setupViews()
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        view.addSubview(bottomButton)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.bottom.left.right.equalToSuperview()
        }
        
        bottomButton.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(Layout.hMargin)
            $0.height.equalTo(swAdaptedValue(48))
            $0.bottom.equalToSuperview().inset(ScreenUtil.safeAreaBottom + swAdaptedValue(12))
        }
    }
    
    // MARK: - UI Components
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("队伍")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        if let conv = conversation {
            bar.setRightTitleButton(title: "跳过") { [weak self] in
                let vc = TeamMapViewController(conversation: conv)
                UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                
                // 从导航栈中移除当前ViewController
                if let navigationController = self?.navigationController {
                    var viewControllers = navigationController.viewControllers
                    if let index = viewControllers.firstIndex(where: { $0 === self }) {
                        viewControllers.remove(at: index)
                        navigationController.setViewControllers(viewControllers, animated: false)
                    }
                }
            }
        }
        return bar
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(cellType: PhoneInputCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .onDrag
        return tableView
    }()
    
    private lazy var bottomButton: UIButton = {
        let bottomButton = UIButton(type: .system)
        bottomButton.setTitle("邀请", for: .normal)
        bottomButton.backgroundColor = ThemeManager.current.mainColor
        bottomButton.setTitleColor(.white, for: .normal)
        bottomButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        bottomButton.layer.cornerRadius = 8
        bottomButton.addTarget(self, action: #selector(inviteButtonTapped), for: .touchUpInside)
        
        return bottomButton
    }()
    
    // MARK: - Actions
    
    @objc private func inviteButtonTapped() {
        // 获取所有有效的手机号
        
        let validPhoneNumbers = phoneNumbers.filter { !$0.isEmpty }
        if validPhoneNumbers.count == 0 {
            view.sw_showWarningToast("请输入手机号")
            return
        }
        
        var params = [String : Any]()
        params["requestId"] = Int(Date().timeIntervalSince1970)
        params["teamId"] = teamId
        params["phones"] = validPhoneNumbers
        
        if let jsonStr = params.dataValue?.jsonString {
            MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.joinTeam_pub, qos:.qos1)
        }
        
        if let conv = conversation {
            let vc = TeamMapViewController(conversation: conv)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            navigationController?.popViewController(animated: false)
        }
    }
    
    private func removePhoneNumber(at index: Int) {
        if index < phoneNumbers.count {
            phoneNumbers.remove(at: index)
            tableView.reloadData()
        }
    }
    
    private func addPhoneNumber(_ phoneNumber: String) {
        // 检查是否已存在相同手机号
        if !phoneNumbers.contains(phoneNumber) {
            phoneNumbers.append(phoneNumber)
            tableView.reloadData()
        }
    }
    
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension TeamInviteMemberViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 额外添加一行用于新输入
        return phoneNumbers.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: PhoneInputCell.self)
        
        if indexPath.row < phoneNumbers.count {
            // 已有手机号的行
            cell.phoneTextField.text = phoneNumbers[indexPath.row]
            cell.phoneTextField.placeholder = "手机"
            cell.deleteButton.isHidden = false
            // 创建临时变量存储当前行索引，避免闭包捕获循环变量的问题
            let currentIndex = indexPath.row
            cell.deleteButtonAction = { [weak self] in
                self?.removePhoneNumber(at: currentIndex)
            }
        } else {
            // 新输入行
            cell.phoneTextField.text = ""
            cell.phoneTextField.placeholder = "请输入"
            cell.deleteButton.isHidden = true
        }
        
        // 设置代理和回调
        cell.delegate = self
        cell.indexPath = indexPath
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(56)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 点击时聚焦到对应的输入框
        if let cell = tableView.cellForRow(at: indexPath) as? PhoneInputCell {
            cell.phoneTextField.becomeFirstResponder()
        }
    }
}

// MARK: - Keyboard Handling

extension TeamInviteMemberViewController: UIGestureRecognizerDelegate {

    private func setupTapGestureToDismissKeyboard() {
        // 创建点击手势
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        // 设置点击手势的委托，以便在某些情况下不触发（比如点击了按钮）
        tapGesture.delegate = self
        // 添加手势到视图
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissKeyboard() {
        // 收起键盘
        view.endEditing(true)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if touch.view?.superview is UITableViewCell {
            return false
        }
        return true
    }
}

// MARK: - PhoneInputCellDelegate

extension TeamInviteMemberViewController: PhoneInputCellDelegate {
    
    func phoneInputCell(_ cell: PhoneInputCell, didChangeText text: String, at indexPath: IndexPath) {
        if indexPath.row < phoneNumbers.count {
            // 更新已有手机号
            phoneNumbers[indexPath.row] = text
        }
        
//        let validPhoneNumbers = phoneNumbers.filter { !$0.isEmpty }
//        if validPhoneNumbers.count > 0 {
//            bottomButton.isEnabled = true
//            bottomButton.backgroundColor = ThemeManager.current.mainColor
//        } else {
//            bottomButton.isEnabled = false
//            bottomButton.backgroundColor = UIColor(str: "#FFE0B9")
//        }
    }
    
    func phoneInputCellDidBeginEditing(_ cell: PhoneInputCell, at indexPath: IndexPath) {
        activeTextFieldIndexPath = indexPath
    }
    
    func phoneInputCellDidEndEditing(_ cell: PhoneInputCell, at indexPath: IndexPath) {
        activeTextFieldIndexPath = nil
        
        // 如果是新输入行且有内容，添加到列表中
        if let text = cell.phoneTextField.text, text.count == 11, indexPath.row == phoneNumbers.count {
            addPhoneNumber(text)
        }
    }
    
    func phoneInputCellShouldReturn(_ cell: PhoneInputCell, at indexPath: IndexPath) -> Bool {
        // 处理键盘返回按钮
        if indexPath.row < phoneNumbers.count {
            // 如果不是最后一行，聚焦到下一行
            let nextIndexPath = IndexPath(row: indexPath.row + 1, section: 0)
            if let nextCell = tableView.cellForRow(at: nextIndexPath) as? PhoneInputCell {
                nextCell.phoneTextField.becomeFirstResponder()
            }
        } else {
            // 最后一行，收起键盘
            cell.phoneTextField.resignFirstResponder()
        }
        return true
    }
}

// MARK: - PhoneInputCell

protocol PhoneInputCellDelegate: AnyObject {
    func phoneInputCell(_ cell: PhoneInputCell, didChangeText text: String, at indexPath: IndexPath)
    func phoneInputCellDidBeginEditing(_ cell: PhoneInputCell, at indexPath: IndexPath)
    func phoneInputCellDidEndEditing(_ cell: PhoneInputCell, at indexPath: IndexPath)
    func phoneInputCellShouldReturn(_ cell: PhoneInputCell, at indexPath: IndexPath) -> Bool
}

class PhoneInputCell: BaseCell {
    
    // MARK: - Properties
    
    weak var delegate: PhoneInputCellDelegate?
    var indexPath: IndexPath?
    var deleteButtonAction: (() -> Void)?
    
    let phoneLabel = UILabel()
    let phoneTextField = UITextField()
    let deleteButton = UIButton(type: .system)
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        selectionStyle = .none
        
        // 手机标签
        phoneLabel.text = "手机"
        phoneLabel.font = UIFont.systemFont(ofSize: 16)
        phoneLabel.textColor = .black
        addSubview(phoneLabel)
        
        // 手机号输入框
        phoneTextField.font = UIFont.systemFont(ofSize: 16)
        phoneTextField.textColor = .black
        phoneTextField.keyboardType = .numberPad
        phoneTextField.delegate = self
        addSubview(phoneTextField)
        
        // 删除按钮
        deleteButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
        deleteButton.tintColor = ThemeManager.current.errorColor
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        addSubview(deleteButton)
        
        // 添加底部边框线
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        addSubview(bottomLine)
        
        bottomLine.snp.makeConstraints {
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
    
    private func setupConstraints() {
        phoneLabel.snp.makeConstraints {
            $0.left.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.equalTo(40)
        }
        
        deleteButton.snp.makeConstraints {
            $0.right.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(30)
        }
        
        phoneTextField.snp.makeConstraints {
            $0.left.equalTo(phoneLabel.snp.right).offset(16)
            $0.right.equalTo(deleteButton.snp.left).offset(-16)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(40)
        }
    }
    
    // MARK: - Actions
    
    @objc private func deleteButtonTapped() {
        deleteButtonAction?()
    }
}

// MARK: - UITextFieldDelegate

extension PhoneInputCell: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let indexPath = indexPath {
            delegate?.phoneInputCellDidBeginEditing(self, at: indexPath)
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let indexPath = indexPath {
            delegate?.phoneInputCellDidEndEditing(self, at: indexPath)
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        return currentText.count <= 11
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if let text = textField.text, let indexPath = indexPath {
            delegate?.phoneInputCell(self, didChangeText: text, at: indexPath)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let indexPath = indexPath {
            return delegate?.phoneInputCellShouldReturn(self, at: indexPath) ?? true
        }
        return true
    }
}
