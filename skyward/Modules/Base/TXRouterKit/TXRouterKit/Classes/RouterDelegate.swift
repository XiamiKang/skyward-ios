//
//  RouterDelegate.swift
//  skyward
//
//  Created by 赵波 on 2025/11/11.
//

import UIKit

public protocol RoutableTypeDelegate: AnyObject {
    func shouldShowController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind, shouldShow: @escaping (Bool) -> Void)
    func willShowController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind)
    func didShownController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind)
}

public protocol RouterDelegate: RoutableTypeDelegate { }

extension RouterDelegate {
    public func shouldShowController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind, shouldShow: @escaping (Bool) -> Void) {
        shouldShow(true)
    }
    
    public func willShowController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind) { }
    
    public func didShownController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind) { }
}

extension RoutableTypeDelegate {
    public func shouldShowController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind, shouldShow: @escaping (Bool) -> Void) {
        shouldShow(true)
    }
    
    public func willShowController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind) { }
    
    public func didShownController(_ controller: UIViewController, fromViewController: UIViewController, segueKind: SegueKind) { }
}
