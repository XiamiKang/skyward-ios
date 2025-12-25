//
//  ContactViewController.swift
//  ModuleMessage
//
//  Created by zhaobo on 2025/11/19.
//

import TXKit
import TXRouterKit
import SWKit
import SWTheme
import SnapKit


class ContactViewController: BaseViewController {
    // MARK: - Override
    override public var hasNavBar: Bool {
        return false
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .green
    }
}
