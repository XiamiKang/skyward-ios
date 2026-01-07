//
//  MiniDeviceMsgViewController.swift
//  SWKit
//
//  Created by TXTS on 2025/12/15.
//

import UIKit
import SWKit

struct BufferMsgData {
    let imgStr: String
    let titleStr: String
    let numStr: Int
}

class MiniDeviceNoSendMsgViewController: PersonalBaseViewController {
    
    let noMsgView = UIView()
    let noMsgImageView = UIImageView()
    let noMsgText = UILabel()
    // 使用字典来管理不同类型的数据，方便更新和排序
    private var bufferData: [MessageType: Int] = [:]
    
    // 定义消息类型和优先级
    enum MessageType: Int, CaseIterable {
        case sos = 0      // 最高优先级
        case safe = 1
        case location = 2
        case custom = 3   // 最低优先级
        
        var displayInfo: (imageName: String, title: String) {
            switch self {
            case .sos:
                return ("device_mini_buffer_sos", "SOS报警")
            case .safe:
                return ("device_mini_buffer_safe", "报平安")
            case .location:
                return ("device_mini_buffer_location", "设备定位")
            case .custom:
                return ("device_mini_buffer_msg", "自定义消息")
            }
        }
        
        var priority: Int { return rawValue }
    }
    
    // 计算属性：生成排序后的数据源
    private var sortedDataSource: [BufferMsgData] {
        return MessageType.allCases
            .sorted { $0.priority < $1.priority } // 按优先级升序排序
            .compactMap { type in
                guard let count = bufferData[type], count > 0 else { return nil }
                let info = type.displayInfo
                return BufferMsgData(imgStr: info.imageName,
                                     titleStr: info.title,
                                     numStr: count)
            }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.register(DevieceBufferMsgCell.self, forCellReuseIdentifier: "DevieceBufferMsgCell")
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraint()
        setupNotifications()
        initializeData()
    }
    
    private func initializeData() {
        // 初始化所有消息类型为0
        MessageType.allCases.forEach { bufferData[$0] = 0 }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        customTitle.text = "待发送队列"
        
        self.view.addSubview(tableView)
        
        noMsgView.backgroundColor = .white
        self.view.addSubview(noMsgView)
        
        noMsgImageView.image = PersonalModule.image(named: "device_mini_noMsg")
        noMsgView.addSubview(noMsgImageView)
        
        noMsgText.text = "暂无消息"
        noMsgText.textColor = UIColor(str: "#74777B")
        noMsgText.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        noMsgView.addSubview(noMsgText)
    }
    
    private func setupConstraint() {
        noMsgView.translatesAutoresizingMaskIntoConstraints = false
        noMsgImageView.translatesAutoresizingMaskIntoConstraints = false
        noMsgText.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            noMsgView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 16),
            noMsgView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noMsgView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noMsgView.heightAnchor.constraint(equalToConstant: 300),
            
            noMsgImageView.centerXAnchor.constraint(equalTo: noMsgView.centerXAnchor),
            noMsgImageView.topAnchor.constraint(equalTo: noMsgView.topAnchor, constant: 80),
            noMsgImageView.widthAnchor.constraint(equalToConstant: 96),
            noMsgImageView.heightAnchor.constraint(equalToConstant: 96),
            
            noMsgText.centerXAnchor.constraint(equalTo: noMsgView.centerXAnchor),
            noMsgText.topAnchor.constraint(equalTo: noMsgImageView.bottomAnchor, constant: 5),
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showDeviceBufferInfo(_:)),
                                               name: .didDeviceBufferInfo,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showAlarmInfo(_:)),
                                               name: .didReceiveAlarmReport,
                                               object: nil)
    }
    
    @objc private func showDeviceBufferInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let deviceBufferInfo = userInfo["deviceBufferInfo"] as? Data {
//            print("Mini设备缓存区信息---\(deviceBufferInfo.hexString)")
            noMsgView.isHidden = true
            guard let communicationFrame = BluetoothManager.shared.parseCommunicationFrame(deviceBufferInfo) else { return }
            // 根据命令码更新对应类型的数量
            switch communicationFrame.commandCode {
            case .alarmReport:
                // alarmReport交给showAlarmInfo处理
                BluetoothManager.shared.handleAlarmReport(communicationFrame.messageContent)
            case .positionReport:
                updateMessageCount(for: .location, increment: 1)
            case .appCustomData:
                updateMessageCount(for: .custom, increment: 1)
            default:
                break
            }
            refreshTableView()
        }else {
            noMsgView.isHidden = false
        }
    }
    
    @objc private func showAlarmInfo(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if let alarmInfo = userInfo["alarmInfo"] as? AlarmInfo {
            switch alarmInfo.alarmType {
            case 0: // SOS
                updateMessageCount(for: .sos, increment: 1)
            case 1: // 报平安
                updateMessageCount(for: .safe, increment: 1)
            default:
                break
            }
            
            refreshTableView()
        }
    }
    
    private func updateMessageCount(for type: MessageType, increment: Int = 1) {
        let currentCount = bufferData[type] ?? 0
        bufferData[type] = currentCount + increment
    }
    
    private func refreshTableView() {
        // 检查是否有数据
        let hasData = bufferData.values.contains { $0 > 0 }
        noMsgView.isHidden = hasData
        tableView.isHidden = !hasData
        
        if hasData {
            tableView.reloadData()
        }
    }
}

extension MiniDeviceNoSendMsgViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedDataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DevieceBufferMsgCell") as! DevieceBufferMsgCell
        
        let bufferMsgData = sortedDataSource[indexPath.row]
        cell.configure(with: bufferMsgData)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // 或者你想要的合适高度
    }
    
}

class DevieceBufferMsgCell: UITableViewCell {
    static let identifier = "DevieceBufferMsgCell"
    
    // MARK: - UI Components
    private let msgImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        return label
    }()
    
    private let numLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.backgroundColor = UIColor(str: "#F7594B")
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 9
        return label
    }()
    
    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        contentView.addSubview(msgImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(numLabel)
        
        msgImageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        numLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            msgImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            msgImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            msgImageView.widthAnchor.constraint(equalToConstant: 40),
            msgImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: msgImageView.trailingAnchor, constant: 8),
            
            numLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            numLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 10),
            numLabel.widthAnchor.constraint(equalToConstant: 80),
            numLabel.heightAnchor.constraint(equalToConstant: 18),
        ])
        
        // 设置单元格样式
        selectionStyle = .none
        backgroundColor = .clear
    }
    
    // MARK: - Configuration
    func configure(with bufferMsgData: BufferMsgData) {
        msgImageView.image = PersonalModule.image(named: bufferMsgData.imgStr)
        nameLabel.text = bufferMsgData.titleStr
        numLabel.text = "\(bufferMsgData.numStr)条待发送"
    }
    
    // MARK: - Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        msgImageView.image = nil
        nameLabel.text = nil
        numLabel.text = nil
    }
}
