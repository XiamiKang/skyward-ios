//
//  UIView+Extensions.swift
//  SWKit
//
//  Created by zhaobo on 2025/11/24.
//

import UIKit

public extension UIView {
    
    // MARK: - Toast
    
    func sw_showSuccessToast(_ message: String) {
        guard !message.isEmpty else {
            return
        }
        makeToast(message, image: SWKitModule.image(named: "toast_success"))
    }
    
    func sw_showWarningToast(_ message: String) {
        guard !message.isEmpty else {
            return
        }
        makeToast(message, image: SWKitModule.image(named: "toast_warning"))
    }
    // MARK: - Loading
    
    func sw_showLoading() {
        makeToastActivity(.center)
    }
    
    func sw_hideLoading() {
        hideToastActivity()
    }
}
