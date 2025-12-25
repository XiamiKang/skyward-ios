//
//  GCD.swift
//
//
//  Created by hushijun on 2024/4/2.
//  Copyright © 2024 Longfor. All rights reserved.
//

import Foundation

public typealias DelayTask = (_ cancel: Bool) -> Void


public extension DispatchQueue {
    /// 延迟执行
    static func mp_asyncAfter(_ time: Double, block: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            block()
        }
    }
}




/// 支持 GCD 取消操作
@discardableResult
public func delayTask(_ time: TimeInterval, delayBlock: @escaping () -> Void) -> DelayTask? {
    
    func dispatch_later(block: @escaping () -> Void) {
        let t = DispatchTime.now() + time
        DispatchQueue.main.asyncAfter(deadline: t, execute: block)
    }

    var closure: (() -> Void)? = delayBlock
    var result: DelayTask?
    
    let delayedClosure: DelayTask = {
        cancel in
        if let internalClosure = closure {
            if cancel == false {
                DispatchQueue.main.async(execute: internalClosure)
            }
        }
        closure = nil
        result = nil
    }
    
    result = delayedClosure
    
    dispatch_later {
        if let delayedClosure = result {
            delayedClosure(false)
        }
    }
    
    return result
}

public func cancel(_ task: DelayTask?) {
    task?(true)
}

/// 延迟执行
public func delay(_ time: Double, block: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + time) { block() }
}

/// 在 global 线程执行
public func exchangeGlobalQueue(_ handle: @escaping () -> Void) {
    if Thread.isMainThread {
        DispatchQueue.global().async {
            handle()
        }
    } else {
        handle()
    }
}

/// 在主线程执行
public func exchangeMainQueue(_ handle: @escaping () -> Void) {
    if Thread.isMainThread {
        handle()
    } else {
        DispatchQueue.main.async {
            handle()
        }
    }
}
/// 倒计时
@discardableResult
public func startCountdown(duration: Int,
                    update: @escaping (Int) -> Void,
                           completion: @escaping () -> Void)-> DispatchSourceTimer?  {
    guard duration > 0 else {
        DispatchQueue.main.async {
            update(0)
            completion()
        }
        return nil
    }
    var remainingTime = duration
    let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
    timer.schedule(deadline:.now() + 1, repeating: .seconds(1))
    timer.setEventHandler {
        remainingTime -= 1
        DispatchQueue.main.async {
            update(remainingTime)
        }
        if remainingTime <= 0 {
            timer.cancel()
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    timer.resume()
    return timer
}
/// 加锁执行
public func synchronized(lock: AnyObject, _ closure: @escaping () -> Void) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

extension DispatchQueue {
    public func safeAsync(_ block: @escaping () -> Void) {
        if self == DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}
