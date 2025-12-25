//
//  SunUpAndMoonDownCell.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/8.
//

import UIKit

class SunUpAndMoonDownCell: UITableViewCell {

    private let title = UILabel()
    private let sunView = UPAndDownView()
    private let moonView = UPAndDownView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        
        title.text = "太阳和月亮"
        title.textColor = .black
        title.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        title.translatesAutoresizingMaskIntoConstraints = false
        addSubview(title)
        
        sunView.layer.cornerRadius = 8
        sunView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sunView)
        
        moonView.layer.cornerRadius = 8
        moonView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(moonView)
        
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            title.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            title.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            sunView.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 16),
            sunView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            sunView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            moonView.topAnchor.constraint(equalTo: sunView.bottomAnchor, constant: 10),
            moonView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            moonView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
        ])
    }
    
    func config(_ data: EveryDayWeatherData) {
        print(data)
        if let sunUpTiem = data.sunrise, let sunDownTime = data.sunset {
            sunView.config("sun", upTimeStr: sunUpTiem, downTimeStr: sunDownTime)
        }
        if let moonUpTiem = data.moonrise, let moonDownTime = data.moonset {
            moonView.config("moon", upTimeStr: moonUpTiem, downTimeStr: moonDownTime)
        }
    }
}

class UPAndDownView: UIView {
    
    private var upImageView = UIImageView()
    private var downImageView = UIImageView()
    private var upName = UILabel()
    private var downName = UILabel()
    private let upLineView = UIView()
    private let downLineView = UIView()
    private var upTimeLabel = UILabel()
    private var downTimeLabel = UILabel()
    private var iconImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor(str: "#FAFAFA")
        
        upImageView.contentMode = .scaleAspectFit
        downImageView.contentMode = .scaleAspectFit
        iconImageView.contentMode = .scaleAspectFit
        
        upName.textColor = UIColor(str: "#84888C")
        upName.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        
        downName.textColor = UIColor(str: "#84888C")
        downName.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        downName.textAlignment = .right
        
        upLineView.backgroundColor = UIColor(str: "#DFE0E2")
        upLineView.layer.cornerRadius = 2
        upLineView.layer.masksToBounds = true
        
        downLineView.backgroundColor = UIColor(str: "#A0A3A7")
        downLineView.layer.cornerRadius = 2
        downLineView.layer.masksToBounds = true
        
        upTimeLabel.text = "00:00"
        upTimeLabel.textColor = UIColor(str: "#070808")
        upTimeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        
        downTimeLabel.text = "00:00"
        downTimeLabel.textColor = UIColor(str: "#070808")
        downTimeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        downTimeLabel.textAlignment = .right
        
        addSubview(upImageView)
        addSubview(downImageView)
        addSubview(iconImageView)
        addSubview(upName)
        addSubview(downName)
        addSubview(upLineView)
        addSubview(downLineView)
        addSubview(upTimeLabel)
        addSubview(downTimeLabel)
    }
    
    private func setupConstraint() {
        upImageView.translatesAutoresizingMaskIntoConstraints = false
        downImageView.translatesAutoresizingMaskIntoConstraints = false
        upName.translatesAutoresizingMaskIntoConstraints = false
        downName.translatesAutoresizingMaskIntoConstraints = false
        upLineView.translatesAutoresizingMaskIntoConstraints = false
        downLineView.translatesAutoresizingMaskIntoConstraints = false
        upTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        downTimeLabel.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            upImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            upImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            upImageView.widthAnchor.constraint(equalToConstant: 20),
            upImageView.heightAnchor.constraint(equalToConstant: 20),
            
            downImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            downImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            downImageView.widthAnchor.constraint(equalToConstant: 20),
            downImageView.heightAnchor.constraint(equalToConstant: 20),
            
            upName.topAnchor.constraint(equalTo: upImageView.bottomAnchor, constant: 4),
            upName.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            
            downName.topAnchor.constraint(equalTo: downImageView.bottomAnchor, constant: 4),
            downName.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            
            iconImageView.topAnchor.constraint(equalTo: upName.bottomAnchor, constant: 8),
            iconImageView.centerXAnchor.constraint(equalTo: centerXAnchor, constant: 50),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            upLineView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            upLineView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            upLineView.trailingAnchor.constraint(equalTo: iconImageView.leadingAnchor, constant: -5),
            upLineView.heightAnchor.constraint(equalToConstant: 4),
            
            downLineView.centerYAnchor.constraint(equalTo: iconImageView.centerYAnchor),
            downLineView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 5),
            downLineView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            downLineView.heightAnchor.constraint(equalToConstant: 4),
            
            upTimeLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 5),
            upTimeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            
            downTimeLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 5),
            downTimeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            downTimeLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
            
        ])
    }
    
    func config(_ type: String, upTimeStr: String, downTimeStr: String) {
        if type == "sun" {
            upImageView.image = MapModule.image(named: "sun_up")
            downImageView.image = MapModule.image(named: "sun_down")
            iconImageView.image = MapModule.image(named: "sun")
            upName.text = "日出"
            downName.text = "日落"
        }else {
            upImageView.image = MapModule.image(named: "moon_up")
            downImageView.image = MapModule.image(named: "moon_down")
            iconImageView.image = MapModule.image(named: "moon")
            upName.text = "月升"
            downName.text = "月落"
        }
        upTimeLabel.text = upTimeStr
        downTimeLabel.text = downTimeStr
    }
    
}
