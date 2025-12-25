//
//  TeamSettingEditViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/3.
//

import TXKit
import SWKit
import SWTheme
import SWNetwork

class TeamSettingEditViewController: BaseViewController {
    
    // MARK: - Properties
    var team: Team
    
    // MARK: - Initialization
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @MainActor public init(team: Team) {
        self.team = team
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Over ride
    override public var hasNavBar: Bool {
        return false
    }
    
    override public func setupViews() {
        super.setupViews()
        view.addSubview(navigationBar)
        view.addSubview(tableView)
        
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
    }
    
    // MARK: - UI Components
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("编辑")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return bar
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(cellType: TeamSettingEditCell.self)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    
    // MARK: - Actions
    
   
    //MARK: - private

}

//MARK: - UITableViewDataSource, UITableViewDelegate
extension TeamSettingEditViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: TeamSettingEditCell.self)
        if indexPath.row == 0 {
            cell.configure(with: .image(url: team.teamAvatar), title: "头像")
        } else {
            if let content = team.name {
                cell.configure(with: .text(content: content), title: "队伍昵称")
            } else {
                cell.configure(with: .text(content: ""), title: "队伍昵称")
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return swAdaptedValue(64)
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            
            let customView = TeamModifyNameView()
            SWAlertView.showCustomAlert(title: "修改队伍昵称", customView: customView, confirmTitle: "保存", cancelTitle: "取消", confirmHandler: {
                var params = [String : Any]()
                params["requestId"] = Int(Date().timeIntervalSince1970)
                params["id"] = self.team.id
                params["name"] = customView.textField.text
                
                if let jsonStr = params.dataValue?.jsonString {
                    MQTTManager.shared.publish(message: jsonStr, to: TeamAPI.teamUpdate_pub, qos:.qos1)
                }
            })
        }
    }
}

class TeamModifyNameView: UIView, SWAlertCustomView {
    
    lazy var textField: UITextField = {
        let textField = UITextField()
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textField.font = .pingFangFontMedium(ofSize: 14)
        textField.textColor = ThemeManager.current.titleColor
        textField.tintColor = ThemeManager.current.mainColor
        textField.clearButtonMode = .whileEditing
        textField.placeholder = "请输入队伍昵称"
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
        textField.layer.cornerRadius = CornerRadius.medium.rawValue
        textField.layer.masksToBounds = true
        textField.layer.borderColor = ThemeManager.current.errorColor.cgColor
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Layout.hMargin, height: textField.frame.height))
        textField.leftViewMode = .always
        return textField
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.font = .pingFangFontRegular(ofSize: 12)
        label.textColor = ThemeManager.current.errorColor
        label.textAlignment = .left
        label.numberOfLines = 1
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(textField)
        textField.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(48))
            make.top.left.right.equalToSuperview()
        }
        addSubview(errorLabel)
        errorLabel.snp.makeConstraints { make in
            make.height.equalTo(swAdaptedValue(17))
            make.top.equalTo(textField.snp.bottom).offset(swAdaptedValue(8))
            make.bottom.equalToSuperview().inset(swAdaptedValue(8))
            make.leading.equalTo(textField.snp.leading)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func shouldClickConfirmButton() -> Bool {
        if let text = textField.text, text.count > 20 {
            errorLabel.text = "已达昵称长度上限"
            textField.layer.borderWidth = 1
            return false
        } else {
            errorLabel.text = ""
            textField.layer.borderWidth = 0
            return true
        }
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let text = textField.text, text.count > 20 {
            errorLabel.text = "已达昵称长度上限"
            textField.layer.borderWidth = 1
        } else {
            errorLabel.text = ""
            textField.layer.borderWidth = 0
        }
    }
}
