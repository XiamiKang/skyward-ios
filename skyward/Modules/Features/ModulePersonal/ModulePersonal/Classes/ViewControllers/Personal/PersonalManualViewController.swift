//
//  PersonalManualViewController.swift
//  ModulePersonal
//
//  Created by TXTS on 2026/2/27.
//

import UIKit
import SWKit
import ModuleLogin

struct ManualData {
    let image: String
    let title: String
    let htmlName: String
}

class PersonalManualViewController: PersonalBaseViewController {
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .white
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.rowHeight = 70
        tableview.register(ManualCell.self, forCellReuseIdentifier: "ManualCell")
        return tableview
    }()
    
    private var dataSource: [ManualData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        customTitle.text = "手册"
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: customNavView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func setData() {
        dataSource = [
            ManualData(image: "device_userManual", title: "行者mini使用说明书", htmlName: "MiniUserManual"),
            ManualData(image: "device_set", title: "行者Pro设备快速安装说明", htmlName: "ProInstallationManual"),
            ManualData(image: "device_userManual", title: "行者Pro设备使用手册", htmlName: "ProUserManual"),
        ]
        tableView.reloadData()
    }
}

extension PersonalManualViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ManualCell") as! ManualCell
        let data = dataSource[indexPath.row]
        cell.configure(with: data)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = dataSource[indexPath.row]
        showWebView(with: data)
    }
    
    private func showWebView(with data: ManualData) {
        let webVC = WebViewController(
            fileName: data.htmlName,
            title: data.title
        )
        self.navigationController?.pushViewController(webVC, animated: true)
    }
}


class ManualCell: UITableViewCell {
    
    private let bgView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(str: "#F2F3F4")
        view.layer.cornerRadius = 8
        return view
    }()
    
    private var manualImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private var manualTextLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        return label
    }()
    
    private var manualNextImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.image = PersonalModule.image(named: "cell_suffix")
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        selectionStyle = .none
        
        contentView.addSubview(bgView)
        bgView.addSubview(manualImageView)
        bgView.addSubview(manualTextLabel)
        bgView.addSubview(manualNextImageView)
        
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bgView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            bgView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bgView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            manualImageView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            manualImageView.leadingAnchor.constraint(equalTo: bgView.leadingAnchor, constant: 16),
            manualImageView.widthAnchor.constraint(equalToConstant: 24),
            manualImageView.heightAnchor.constraint(equalToConstant: 24),
            
            manualNextImageView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            manualNextImageView.trailingAnchor.constraint(equalTo: bgView.trailingAnchor, constant: -16),
            manualNextImageView.widthAnchor.constraint(equalToConstant: 16),
            manualNextImageView.heightAnchor.constraint(equalToConstant: 16),
            
            manualTextLabel.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),
            manualTextLabel.leadingAnchor.constraint(equalTo: manualImageView.trailingAnchor, constant: 8),
            manualTextLabel.trailingAnchor.constraint(equalTo: manualNextImageView.leadingAnchor, constant: -8),
        ])
    }
    
    func configure(with data: ManualData) {
        manualImageView.image = PersonalModule.image(named: data.image)
        manualTextLabel.text = data.title
    }
}
