//
//  CustomPointView.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/16.
//

import UIKit

class CustomPointView: UIView {
    
    private let width = 150.0
    private let height = 100.0
    
    private var pointName = UILabel()
    private var closeButton = UIButton()
    private let titleOne = UILabel()
    private var titleOneContent = UILabel()
    private let titleTwo = UILabel()
    private var titleTwoContent = UILabel()
    private let creatPointButton = UIButton()
    
    var closeAction: (()->Void)?
    var creatPointAction: (()->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .white
        self.layer.cornerRadius = 8
        
        pointName.textColor = .black
        pointName.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        pointName.numberOfLines = 2
        self.addSubview(pointName)
        
        closeButton.setImage(MapModule.image(named: "map_close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeClick), for: .touchUpInside)
        self.addSubview(closeButton)
        
        titleOne.text = "经纬度"
        titleOne.textColor = UIColor(str: "#84888C")
        titleOne.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(titleOne)
        
        titleOneContent.textColor = UIColor(str: "#070808")
        titleOneContent.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.addSubview(titleOneContent)
        
        titleTwo.text = "海拔"
        titleTwo.textColor = UIColor(str: "#84888C")
        titleTwo.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(titleTwo)
        
        titleTwoContent.textColor = UIColor(str: "#84888C")
        titleTwoContent.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.addSubview(titleTwoContent)
        
        creatPointButton.setTitle("添加兴趣点", for: .normal)
        creatPointButton.setTitleColor(.white, for: .normal)
        creatPointButton.backgroundColor = UIColor(str: "#FE6A00")
        creatPointButton.titleLabel?.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        creatPointButton.layer.cornerRadius = 6
        creatPointButton.addTarget(self, action: #selector(creatPointClick), for: .touchUpInside)
        self.addSubview(creatPointButton)
        
        setupConstraint()
    }
    
    private func setupConstraint() {
        pointName.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        titleOne.translatesAutoresizingMaskIntoConstraints = false
        titleOneContent.translatesAutoresizingMaskIntoConstraints = false
        titleTwo.translatesAutoresizingMaskIntoConstraints = false
        titleTwoContent.translatesAutoresizingMaskIntoConstraints = false
        creatPointButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            pointName.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            pointName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            pointName.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -10),
            
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            titleOne.topAnchor.constraint(equalTo: pointName.bottomAnchor, constant: 10),
            titleOne.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            titleOneContent.centerYAnchor.constraint(equalTo: titleOne.centerYAnchor),
            titleOneContent.leadingAnchor.constraint(equalTo: titleOne.trailingAnchor, constant: 5),
            titleOneContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            titleTwo.topAnchor.constraint(equalTo: titleOne.bottomAnchor, constant: 5),
            titleTwo.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            titleTwoContent.centerYAnchor.constraint(equalTo: titleTwo.centerYAnchor),
            titleTwoContent.leadingAnchor.constraint(equalTo: titleOneContent.leadingAnchor),
            titleTwoContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            creatPointButton.topAnchor.constraint(equalTo: titleTwo.bottomAnchor, constant: 15),
            creatPointButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            creatPointButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            creatPointButton.heightAnchor.constraint(equalToConstant: 30),
            creatPointButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }
    
    func updateUI(with pointData: MapSearchPointMsgData) {
        pointName.text = pointData.name
        let longitude = pointData.longitude ?? 0.0
        let latitude = pointData.latitude ?? 0.0
        titleOneContent.text = String(format: "%.4f,%.4f", longitude, latitude)
        titleTwoContent.text = "\(pointData.altitude ?? "")米"
    }
    
    
    @objc private func closeClick() {
        closeAction?()
    }
    
    @objc private func creatPointClick() {
        creatPointAction?()
    }
}
