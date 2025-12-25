//
//  DefaultInputField.swift
//  TXTS
//
//  Created by yifan kang on 2025/11/11.
//

import UIKit

class DefaultInputField: BaseInputField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureDefaultSettings()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureDefaultSettings()
    }
    
    private func configureDefaultSettings() {
        textField.keyboardType = .default
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        
        containerHeight = 50
    }
    
    func configure(placeholder: String, validationRule: InputValidationRule = .none) {
        self.placeholder = placeholder
        self.validationRule = validationRule
    }
}
