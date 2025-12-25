//
//  BaseViewModel.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import Foundation
import Combine

public enum DataLoadStatus: Equatable {
    case loading(shouldShowLoading: Bool, message: String?)
    case finished
    case emptyData(message: String?)
    case networkError(isToast: Bool, message: String?)
    
    public func isShowLoading() -> Bool {
        if case .loading(let shouldShowLoading, _) = self {
            return shouldShowLoading
        }
        return false
    }
    
    /// 是否正在请求中
    public func isLoading() -> Bool {
        if case .loading(_, _) = self {
            return true
        }
        return false
    }
    
    public func isEmptyData() -> Bool {
        if case .emptyData = self {
            return true
        }
        return false
    }
    
    public func isNetworkError() -> Bool {
        if case .networkError(let isToast, _) = self {
            return !isToast
        }
        return false
    }
    
    public func isToast() -> Bool {
        if case .networkError(let isToast, _) = self {
            return isToast
        }
        return false
    }
}

open class BaseViewModel: ObservableObject {
    
    @Published public var loadStatus: DataLoadStatus = .finished
    
    public required init() {}
    
    open func shouldShowLoading() -> Bool {
        return loadStatus.isShowLoading()
    }
    
    open func loadingMessage(_ loadStatus: DataLoadStatus) -> String {
        if case .loading(_, let message) = loadStatus, let message = message {
            return message
        }
        return "全力加载中..."
    }
    
    open func emptyDataMessage(_ loadStatus: DataLoadStatus) -> String {
        if case .emptyData(let message) = loadStatus, let message = message {
            return message
        }
        return "暂无数据"
    }
    
    open func networkMessage(_ loadStatus: DataLoadStatus) -> String {
        if case .networkError(_, let message) = loadStatus, let message = message {
            return message
        }
        return "网络异常，请检查"
    }
}
