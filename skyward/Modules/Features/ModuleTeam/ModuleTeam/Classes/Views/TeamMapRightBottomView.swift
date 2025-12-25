//
//  TeamMapRightBottomView.swift
//  ModuleMap
//
//  Created by zhaobo on 2025/12/2.
//

import UIKit
import SWTheme
import SWKit

class TeamMapRightBottomView: UIStackView {
    
    let locationButton: UIButton = UIButton()
    let safeButton: UIButton = UIButton()
    let sosButton: UIButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        axis = .vertical
        spacing = 12
        distribution = .equalSpacing
        alignment = .center
        translatesAutoresizingMaskIntoConstraints = false

        configButton(button: locationButton, imageName: "team_location_icon")
        configButton(button: safeButton, imageName: "team_safety_icon")
        configButton(button: sosButton, imageName: "team_sos_icon")
        
        locationButton.layer.cornerRadius = CornerRadius.large.rawValue
        locationButton.backgroundColor = .white
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configButton(button: UIButton, imageName: String) {
        let image = TeamModule.image(named: imageName)
        button.setImage(image, for: .normal)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: swAdaptedValue(48)),
            button.heightAnchor.constraint(equalToConstant: swAdaptedValue(48))
        ])
        
        addArrangedSubview(button)
    }
    
}

