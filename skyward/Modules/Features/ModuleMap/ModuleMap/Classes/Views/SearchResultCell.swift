//
//  SearchResultCell.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/24.
//

import UIKit
import CoreLocation

class SearchResultCell: UITableViewCell {
    
    var searchPointAction: ((CLLocationCoordinate2D) -> Void)?
    var coordinate: CLLocationCoordinate2D?
    
    private let pointImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = MapModule.image(named: "map_search_point")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let pointName: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pointContent: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(str: "#84888C")
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var pointButton: UIButton = {
        let button = UIButton()
        button.setTitle("导航", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(str: "#FE6A00")
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.layer.cornerRadius = 6
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(checkPointClick), for: .touchUpInside)
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
         setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.selectionStyle = .none
        self.backgroundColor = .clear
        
        contentView.addSubview(pointImageView)
        contentView.addSubview(pointName)
        contentView.addSubview(pointContent)
        contentView.addSubview(pointButton)
        
        NSLayoutConstraint.activate([
            pointImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            pointImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            pointImageView.widthAnchor.constraint(equalToConstant: 24),
            pointImageView.heightAnchor.constraint(equalToConstant: 24),
            
            pointButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            pointButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            pointButton.widthAnchor.constraint(equalToConstant: 60),
            pointButton.heightAnchor.constraint(equalToConstant: 32),
            
            pointName.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 15),
            pointName.leadingAnchor.constraint(equalTo: pointImageView.trailingAnchor, constant: 8),
            pointName.trailingAnchor.constraint(equalTo: pointButton.leadingAnchor, constant: -8),
            
            pointContent.topAnchor.constraint(equalTo: pointName.bottomAnchor, constant: 5),
            pointContent.leadingAnchor.constraint(equalTo: pointImageView.trailingAnchor, constant: 8),
            pointContent.trailingAnchor.constraint(equalTo: pointButton.leadingAnchor, constant: -8),
            pointContent.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -15),
        ])
    }
    
    func configWithData(data: MapSearchPointMsgData) {
        pointName.text = data.name
        pointContent.text = data.address
        if let latitude = data.latitude, let longitude = data.longitude {
            coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    
    @objc private func checkPointClick() {
        if let coordinate = coordinate {
            searchPointAction?(coordinate)
        }
    }
}
