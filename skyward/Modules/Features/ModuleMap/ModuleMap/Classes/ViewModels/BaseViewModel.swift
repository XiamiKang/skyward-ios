//
//  BaseViewModel.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation

public protocol ViewModelProtocol: AnyObject {
    associatedtype Input
    associatedtype Output
    
    var input: Input { get }
    var output: Output { get }
}

public class BaseViewModel: ObservableObject {
    public init() {}
    
    deinit {
        print("🗑️ \(String(describing: type(of: self))) deinit")
    }
}
