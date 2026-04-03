//
//  SearchResultView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/24.
//

import UIKit
import CoreLocation
import SWNetwork
import SWKit

class SearchResultView: UIView {
    
    private let viewModel = MapViewModel()
    private var resultData: [MapSearchPointMsgData] = []
    
    var choosePointAction: ((MapSearchPointMsgData) -> Void)?
    var touchCellAction: ((MapSearchPointMsgData) -> Void)?
    
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
        
        self.addSubview(tableView)
        self.addSubview(noResultView)
        self.addSubview(noNetworkView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            tableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20),
            
            noResultView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            noResultView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            noResultView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: 0),
            noResultView.heightAnchor.constraint(equalToConstant: 250),
            
            noNetworkView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
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
}

extension SearchResultView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell") as! SearchResultCell
        let data = resultData[indexPath.row]
        cell.configWithData(data: data)
        cell.searchPointAction = { [weak self] data in
            guard let self = self else { return }
            self.choosePointAction?(data)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let data = resultData[indexPath.row]
        touchCellAction?(data)
    }
}
