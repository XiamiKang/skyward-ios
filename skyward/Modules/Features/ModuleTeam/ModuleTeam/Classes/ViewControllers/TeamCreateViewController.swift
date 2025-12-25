//
//  TeamCreateViewController.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/1.
//

import UIKit
import TXKit
import SWKit
import SWTheme
import SWNetwork
import SnapKit
import Photos
import PhotosUI

class TeamCreateViewController: BaseViewController {
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTapGestureToDismissKeyboard()
    }

    
    override var hasNavBar: Bool {
        return false
    }
    
    override func setupViews() {
        view.addSubview(navigationBar)
        view.addSubview(avatarImageView)
        view.addSubview(editButton)
        view.addSubview(teamNameTextField)
        view.addSubview(confirmButton)
    }
    
    override func setupConstraints() {
        navigationBar.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().inset(ScreenUtil.statusBarHeight)
        }
        
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(72))
            make.centerX.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(swAdaptedValue(24))
        }
        
        editButton.snp.makeConstraints { make in
            make.width.height.equalTo(swAdaptedValue(32))
            make.bottom.right.equalTo(avatarImageView)
        }
        
        teamNameTextField.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.hMargin)
            make.height.equalTo(swAdaptedValue(48))
            make.top.equalTo(avatarImageView.snp.bottom).offset(swAdaptedValue(24))
        }
        
        confirmButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.hMargin)
            make.height.equalTo(swAdaptedValue(48))
            make.top.equalTo(teamNameTextField.snp.bottom).offset(swAdaptedValue(48))
        }
    }
    
    // MARK: - UI Components
    
    private lazy var navigationBar: SWNavigationBar = {
        let bar = SWNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        bar.setTitle("创建队伍")
        bar.setLeftBackButton { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        return bar
    }()
    
    // 头像按钮
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView(image: TeamModule.image(named: "team_group_avatar"))
        imageView.cornerRadius = swAdaptedValue(36)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var editButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(TeamModule.image(named: "team_avatar_edit"), for: .normal)
        button.addTarget(self, action: #selector(avatarButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // 队伍名称输入框
    private lazy var teamNameTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "请输入队伍名称"
        textField.font = .pingFangFontBold(ofSize: 14)
        textField.textColor = ThemeManager.current.titleColor
        textField.backgroundColor = ThemeManager.current.mediumGrayBGColor
        textField.layer.cornerRadius = 8
        textField.clipsToBounds = true
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 15, height: 0))
        textField.leftViewMode = .always
        textField.tintColor = ThemeManager.current.mainColor
        return textField
    }()
    
    // 确定按钮
    private lazy var confirmButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("确定", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = ThemeManager.current.mainColor
        button.layer.cornerRadius = CornerRadius.medium.rawValue
        button.clipsToBounds = true
        button.titleLabel?.font = .pingFangFontBold(ofSize: 16)
        button.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Actions
    
    @objc private func avatarButtonTapped() {
        dismissKeyboard()
        // 请求相册访问权限
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    // 有权限，打开相册选择器
                    self?.showPhotoPicker()
                case .denied, .restricted:
                    // 无权限，提示用户去设置中开启
                    self?.showPermissionAlert()
                case .notDetermined:
                    // 权限未确定，应该不会进入这个分支
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func showPhotoPicker() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showPermissionAlert() {
        let alert = UIAlertController(title: "需要相册权限", message: "请在设置中允许访问相册，以便更换队伍头像", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "取消", style: .cancel)
        let settingAction = UIAlertAction(title: "去设置", style: .default) { _ in
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(settingsURL)
        }
        alert.addAction(cancelAction)
        alert.addAction(settingAction)
        present(alert, animated: true)
    }
    
    @objc private func confirmButtonTapped() {
        dismissKeyboard()
        guard let teamName = teamNameTextField.text, !teamName.isEmpty else {
            view.sw_showWarningToast("队伍名称不能为空")
            return
        }
        guard let teamName = teamNameTextField.text, !teamName.isEmpty else {
            // 显示提示信息
            return
        }
        self.view.sw_showLoading()
        NetworkProvider<TeamAPI>().request(.creatTeam(name: teamName), completion: {[weak self] result in
            self?.view.sw_hideLoading()
            switch result {
            case .success(let rsp):
                do {
                    let networkResponse = try rsp.map(NetworkResponse<Team>.self)
                    if networkResponse.isSuccess, let teamData = networkResponse.data {
                        guard let convId = teamData.conversationId else { return }
                        let conversation = Conversation(id: convId, teamId:teamData.id, teamSize: Int(teamData.number ?? ""), name: teamData.name, type: .group, createTime: teamData.createdTime)
                        let vc = TeamInviteMemberViewController(conversation: conversation)
                        UIWindow.topViewController()?.navigationController?.pushViewController(vc, animated: true)
                        UIWindow.topWindow?.sw_showSuccessToast("队伍创建成功")
                        // 从导航栈中移除当前ViewController
                        if let navigationController = self?.navigationController {
                            var viewControllers = navigationController.viewControllers
                            if let index = viewControllers.firstIndex(where: { $0 === self }) {
                                viewControllers.remove(at: index)
                                navigationController.setViewControllers(viewControllers, animated: false)
                            }
                        }
                    } else {
                        self?.view.sw_showWarningToast(networkResponse.msg ?? "")
                    }
                } catch {
                    self?.view.sw_showWarningToast(error.localizedDescription)
                }
                
            case .failure(let error):
                self?.view.sw_showWarningToast(error.localizedDescription)
            }
        })
    }
    
    // MARK: - Keyboard Handling
    
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
    
    /// 设置是否允许点击收起键盘
    /// - Parameter enabled: true允许收起，false不允许
    func setTapToDismissKeyboardEnabled(_ enabled: Bool) {
        if enabled {
            setupTapGestureToDismissKeyboard()
        } else {
            // 移除所有点击手势
            view.gestureRecognizers?.removeAll(where: { $0 is UITapGestureRecognizer })
        }
    }
    
    
}


extension TeamCreateViewController: PHPickerViewControllerDelegate, UIGestureRecognizerDelegate {
    
    // MARK: - PHPickerViewControllerDelegate
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                if let error = error {
                    print("[头像选择] 加载图片失败: \(error)")
                    return
                }
                
                DispatchQueue.main.async {
                    if let selectedImage = image as? UIImage {
                        // 更新头像图片
                        self?.avatarImageView.image = selectedImage
                    }
                }
            }
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 如果点击的是按钮或其他需要交互的控件，不触发收起键盘的手势
        return !(touch.view is UIButton || touch.view is UIScrollView)
    }
}
