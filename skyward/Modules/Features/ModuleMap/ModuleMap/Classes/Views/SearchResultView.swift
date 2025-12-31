//
//  SearchResultView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/24.
//

import UIKit
import CoreLocation
import SWNetwork

class SearchResultView: UIView {
    
    private let viewModel = MapViewModel()
    private var resultData: [MapSearchPointMsgData] = []
    var closeAction: (() -> Void)?
    var choosePointAction: ((CLLocationCoordinate2D) -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "搜索结果"
        label.textColor = .black
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(MapModule.image(named: "map_close"), for: .normal)
        button.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let noResultView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let iv = UIImageView()
        iv.image = MapModule.image(named: "map_search_noResult")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iv)
        let label = UILabel()
        label.text = "暂未搜索到结果"
        label.textColor = UIColor(str: "#84888C")
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            iv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iv.widthAnchor.constraint(equalToConstant: 96),
            iv.heightAnchor.constraint(equalToConstant: 96),
            
            label.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 2),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
        ])
        view.isHidden = true
        return view
    }()
    
    private let noNetworkView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        let iv = UIImageView()
        iv.image = MapModule.image(named: "map_search_noNetwork")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(iv)
        let label = UILabel()
        label.text = "无法连接网络，请检查网络设置或稍后重试"
        label.textColor = UIColor(str: "#84888C")
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            iv.topAnchor.constraint(equalTo: view.topAnchor, constant: 50),
            iv.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iv.widthAnchor.constraint(equalToConstant: 96),
            iv.heightAnchor.constraint(equalToConstant: 96),
            
            label.topAnchor.constraint(equalTo: iv.bottomAnchor, constant: 2),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -5),
        ])
        view.isHidden = true
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 66 // 设置一个预估高度
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(SearchResultCell.self, forCellReuseIdentifier: "SearchResultCell")
        return tableView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        
        self.addSubview(titleLabel)
        self.addSubview(closeButton)
        self.addSubview(tableView)
        self.addSubview(noResultView)
        self.addSubview(noNetworkView)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 5),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            
            noResultView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            noResultView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            noResultView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            noResultView.heightAnchor.constraint(equalToConstant: 250),
            
            noNetworkView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            noNetworkView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            noNetworkView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            noNetworkView.heightAnchor.constraint(equalToConstant: 250),
        ])
    }
    
    func configWithSearchData(searchData: [MapSearchPointMsgData], isNetwork: Bool = true) {
        if isNetwork {
            if searchData.count != 0 {
                resultData = searchData
                tableView.reloadData()
            }else {
                noResultView.isHidden = false
            }
        }else {
            noNetworkView.isHidden = false
        }
        
    }
    
    
    @objc func closeClick() {
        closeAction?()
    }
}

extension SearchResultView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell") as! SearchResultCell
        let data = resultData[indexPath.row]
        cell.configWithData(data: data)
        cell.searchPointAction = { [weak self] coordinate in
            guard let self = self else { return }
            self.choosePointAction?(coordinate)
        }
        return cell
    }
    
    
}
