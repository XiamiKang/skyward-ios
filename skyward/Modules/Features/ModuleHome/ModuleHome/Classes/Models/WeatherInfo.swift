//
//  WeatherInfo.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/24.
//

import Foundation

struct WeatherInfo: Codable {
    /// 观测时间
    let obsTime: String?
    /// 海拔高度（米）
    let altitude: String?
    /// 温度（摄氏度）
    let temp: String?
    /// 体感温度（摄氏度）
    let feelsLike: String?
    /// 天气图标代码
    let icon: String?
    /// 天气状况文字描述
    let text: String?
    /// 风向360角度
    let wind360: String?
    /// 风向
    let windDir: String?
    /// 风向等级
    let windScale: String?
    /// 风速（公里/小时）
    let windSpeed: String?
    /// 相对湿度（百分比）
    let humidity: String?
    /// 降水量（毫米）
    let precip: String?
    /// 大气压强（百帕）
    let pressure: String?
    /// 能见度（公里）
    let vis: String?
    /// 云量（百分比）
    let cloud: String?
    /// 露点温度（摄氏度）
    let dew: String?
}
