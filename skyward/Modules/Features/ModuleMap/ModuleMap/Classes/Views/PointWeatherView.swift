//
//  CustomPointView 2.swift
//  Pods
//
//  Created by TXTS on 2026/1/30.
//

import UIKit
import CoreLocation

class PointWeatherView: UIView {
    
    private let width = 150.0
    private let height = 100.0
    
    private var pointName = UILabel()
    private var closeButton = UIButton()
    private let titleOne = UILabel()
    private var titleOneContent = UILabel()
    private let titleTwo = UILabel()
    private var titleTwoContent = UILabel()
    private let titleThree = UILabel()
    private var titleThreeContent = UILabel()
    private let titleFour = UILabel()
    private var titleFourContent = UILabel()
    private let titleFive = UILabel()
    private var titleFiveContent = UILabel()
    private let titleSix = UILabel()
    private var titleSixContent = UILabel()
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
        
        titleOne.text = "天气"
        titleOne.textColor = UIColor(str: "#84888C")
        titleOne.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(titleOne)
        
        titleOneContent.textColor = UIColor(str: "#070808")
        titleOneContent.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.addSubview(titleOneContent)
        
        titleTwo.text = "温度"
        titleTwo.textColor = UIColor(str: "#84888C")
        titleTwo.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(titleTwo)
        
        titleTwoContent.textColor = UIColor(str: "#070808")
        titleTwoContent.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.addSubview(titleTwoContent)
        
        titleThree.text = "高程"
        titleThree.textColor = UIColor(str: "#84888C")
        titleThree.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(titleThree)
        
        titleThreeContent.textColor = UIColor(str: "#070808")
        titleThreeContent.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.addSubview(titleThreeContent)
        
        titleFour.text = "湿度"
        titleFour.textColor = UIColor(str: "#84888C")
        titleFour.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(titleFour)
        
        titleFourContent.textColor = UIColor(str: "#070808")
        titleFourContent.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.addSubview(titleFourContent)
        
        titleFive.text = "风"
        titleFive.textColor = UIColor(str: "#84888C")
        titleFive.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(titleFive)
        
        titleFiveContent.textColor = UIColor(str: "#070808")
        titleFiveContent.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.addSubview(titleFiveContent)
        
        titleSix.text = "气压"
        titleSix.textColor = UIColor(str: "#84888C")
        titleSix.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        self.addSubview(titleSix)
        
        titleSixContent.textColor = UIColor(str: "#070808")
        titleSixContent.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        self.addSubview(titleSixContent)
        
        creatPointButton.setTitle("天气详情", for: .normal)
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
        titleThree.translatesAutoresizingMaskIntoConstraints = false
        titleThreeContent.translatesAutoresizingMaskIntoConstraints = false
        titleFour.translatesAutoresizingMaskIntoConstraints = false
        titleFourContent.translatesAutoresizingMaskIntoConstraints = false
        titleFive.translatesAutoresizingMaskIntoConstraints = false
        titleFiveContent.translatesAutoresizingMaskIntoConstraints = false
        titleSix.translatesAutoresizingMaskIntoConstraints = false
        titleSixContent.translatesAutoresizingMaskIntoConstraints = false
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
            titleOneContent.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            titleOneContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            titleTwo.topAnchor.constraint(equalTo: titleOne.bottomAnchor, constant: 5),
            titleTwo.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            titleTwoContent.centerYAnchor.constraint(equalTo: titleTwo.centerYAnchor),
            titleTwoContent.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            titleTwoContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            titleThree.topAnchor.constraint(equalTo: titleTwo.bottomAnchor, constant: 10),
            titleThree.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            titleThreeContent.centerYAnchor.constraint(equalTo: titleThree.centerYAnchor),
            titleThreeContent.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            titleThreeContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            titleFour.topAnchor.constraint(equalTo: titleThree.bottomAnchor, constant: 5),
            titleFour.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            titleFourContent.centerYAnchor.constraint(equalTo: titleFour.centerYAnchor),
            titleFourContent.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            titleFourContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            titleFive.topAnchor.constraint(equalTo: titleFour.bottomAnchor, constant: 10),
            titleFive.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            titleFiveContent.centerYAnchor.constraint(equalTo: titleFive.centerYAnchor),
            titleFiveContent.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            titleFiveContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            titleSix.topAnchor.constraint(equalTo: titleFive.bottomAnchor, constant: 5),
            titleSix.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            
            titleSixContent.centerYAnchor.constraint(equalTo: titleSix.centerYAnchor),
            titleSixContent.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 60),
            titleSixContent.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            creatPointButton.topAnchor.constraint(equalTo: titleSix.bottomAnchor, constant: 15),
            creatPointButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            creatPointButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            creatPointButton.heightAnchor.constraint(equalToConstant: 30),
            creatPointButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
    }
    
    func updateUI(with weatherData: WeatherData, coordinate: CLLocationCoordinate2D) {
        pointName.text = String(format: "%.6f°E, %.6f°N", coordinate.longitude, coordinate.latitude)
        titleOneContent.text = weatherData.text
        titleTwoContent.text = "\(weatherData.temp ?? "0")℃"
        titleThreeContent.text = "\(weatherData.altitude ?? "0")米"
        titleFourContent.text = "\(weatherData.humidity ?? "0")%"
        titleFiveContent.text = "\(weatherData.windDir ?? "无")\(weatherData.windDir ?? "无")"
        titleSixContent.text = "\(weatherData.pressure ?? "0")百帕"
    }
    
    
    @objc private func closeClick() {
        closeAction?()
    }
    
    @objc private func creatPointClick() {
        creatPointAction?()
    }
}
