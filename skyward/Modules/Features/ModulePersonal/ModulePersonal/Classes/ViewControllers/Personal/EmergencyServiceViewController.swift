//
//  EmergencyServiceViewController.swift
//  ModulePersonal
//
//  Created by zhaobo on 2025/12/15.
//

import UIKit
import TXKit
import SWKit
import Combine
import SWTheme

class EmergencyServiceViewController: PersonalBaseViewController {
    
    private let viewModel = PersonalViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var bgImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFill
        iv.image = PersonalModule.image(named: "emergency_bg")
        return iv
    }()
    
    private lazy var emergencyTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "管理紧急联系人"
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    private lazy var emergencyContentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "完成绑定后，SOS与报平安将自动通知紧急联系人，保障你的安全，及时获得帮助。"
        label.textColor = .white
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        iv.image = PersonalModule.image(named: "emergency_icon")
        return iv
    }()
    
    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.translatesAutoresizingMaskIntoConstraints = false
        tableview.backgroundColor = .clear
        tableview.separatorStyle = .none
        tableview.delegate = self
        tableview.dataSource = self
        tableview.isScrollEnabled = false
        tableview.rowHeight = 70
        tableview.register(EmergencyAddCell.self, forCellReuseIdentifier: "EmergencyAddCell")
        tableview.register(EmergencyUserCell.self, forCellReuseIdentifier: "EmergencyUserCell")
        return tableview
    }()
    
    var dataSource: [EmergencyInfoData] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadEmergencyData()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.sendSubviewToBack(bgImageView)
    }
    
    private func setupUI() {
        view.backgroundColor = ThemeManager.current.mediumGrayBGColor
        
        backButton.setImage(PersonalModule.image(named: "default_back_white"), for: .normal)
        
        view.addSubview(bgImageView)
        view.addSubview(iconImageView)
        view.addSubview(emergencyTitleLabel)
        view.addSubview(emergencyContentLabel)
        view.addSubview(tableView)
        
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            
            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height/2.8),
            
            iconImageView.topAnchor.constraint(equalTo: customNavView.bottomAnchor, constant: 20),
            iconImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            iconImageView.widthAnchor.constraint(equalToConstant: 72),
            iconImageView.heightAnchor.constraint(equalToConstant: 72),
            
            emergencyTitleLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor, constant: 5),
            emergencyTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emergencyTitleLabel.trailingAnchor.constraint(equalTo: iconImageView.leadingAnchor, constant: -16),
            
            emergencyContentLabel.topAnchor.constraint(equalTo: emergencyTitleLabel.bottomAnchor, constant: 5),
            emergencyContentLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            emergencyContentLabel.trailingAnchor.constraint(equalTo: iconImageView.leadingAnchor, constant: -16),
            
            tableView.topAnchor.constraint(equalTo: emergencyContentLabel.bottomAnchor, constant: 40),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
    
    private func loadEmergencyData() {
        viewModel.getEmergencyList()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] data in
                guard let self = self else { return }
                self.dataSource = data
                self.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

extension EmergencyServiceViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if dataSource.count == 0 {
            return 1
        }else if dataSource.count < 3 {
            return dataSource.count + 1
        }else {
            return 3
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if dataSource.count == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmergencyAddCell") as! EmergencyAddCell
            return cell
        }else if dataSource.count < 3 {
            if indexPath.row == dataSource.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EmergencyAddCell") as! EmergencyAddCell
                return cell
            }else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "EmergencyUserCell") as! EmergencyUserCell
                let data = dataSource[indexPath.row]
                cell.config(with: data)
                return cell
            }
        }else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmergencyUserCell") as! EmergencyUserCell
            let data = dataSource[indexPath.row]
            cell.config(with: data)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = EmergencyContactViewController()
        if dataSource.count > indexPath.row {
            let data = dataSource[indexPath.row]
            vc.emergencyData = data
            vc.isHideDelete = dataSource.count < 2
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


