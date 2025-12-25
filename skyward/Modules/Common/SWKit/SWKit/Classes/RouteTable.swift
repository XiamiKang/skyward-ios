//
//  RouteTable.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//
/**
1、APP中的所有路由地址，都统一在这里配置，
2、通过扩展的方式，按模块划分不同的路由地址
3、路由分页面路由和功能路由
    页面路由：有UI界面的路由 如sw://auth/login
    功能路由：没有UI界面的路由 如sw://auth/logout
4、路由的逻辑写到各个模块中
*/
import Foundation


public struct RouteTable {
    // 首页
    public static let homePageUrl = "sw://home/index"
    // 地图
    public static let mapPageUrl = "sw://map/index"
    // 会话页
    public static let convPageUrl = "sw://message/conv"
    // 紧急消息页
    public static let urgentMessagePageUrl = "sw://message/urgentMessage"
    // 我的
    public static let minePageUrl = "sw://mine/index"
    // 设置
    public static let settingPageUrl = "sw://mine/setting"
    // 登录页面
    public static let loginPageUrl = "sw://auth/login"
    // 修改密码
    public static let resetPWPageUrl = "sw://auth/resetPW"
    // 退出登录
    public static let logoutUrl = "sw://auth/logout"
    // 队伍页（没有队伍去插创建队伍，有队伍去队伍列表）
    public static let teamPageUrl = "sw://team/index"
    
    // 绑定设备页面
    public static let bindDevicePageUrl = "sw://device/bindDevicePage"
}
