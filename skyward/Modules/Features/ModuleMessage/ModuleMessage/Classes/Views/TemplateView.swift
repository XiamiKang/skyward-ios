//
//  TemplateView.swift
//  ModuleMessage
//
//  Created by zhaobo on 2026/1/28.
//

import UIKit
import TXKit

class TemplateView: UIView, UITableViewDataSource, UITableViewDelegate {
    var onSelectedHandler: ((String) -> Void)?
    private var templates: [String] = []
    
    init(templates: [String]) {
        self.templates = templates
        super.init(frame: .zero)

        let tableView = UITableView(frame: .zero)
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 2, left: 0, bottom: 0, right: 0)
        tableView.register(cellType: TemplateCell.self)
        addSubview(tableView)

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templates.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(for: indexPath, cellType: TemplateCell.self)
        cell.messageLabel.text = templates[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let template = templates[indexPath.row]
        onSelectedHandler?(template)
    }
    
}
