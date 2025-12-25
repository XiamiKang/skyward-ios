//
//  ResponseModels.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import SWKit

// 响应数据模型
public struct RouteListData: Codable {
    public let list: [RouteData]?   // 路线类型(0-路线 1-自动轨迹)
    public let total: Int?
}

public struct RouteData: Codable {
    public let id: String?
    public let routeName: String?
    public let startName: String?
    public let startLongitude: String?
    public let startLatitude: TimeInterval?
    public let endName: String?
    public let endLongitude: String?
    public let endLatitude: String?
    public let distance: String?
    public let travelTime: String?
    public let description: String?
    public let coordinates: [Coordinate]?
    public let imgUrlList: [String]?
    public let type: Int?
}

public struct MapSearchPointMsgData: Codable {
    public let regionCode: String?
    public let name: String?
    public let address: String?
    public let longitude: Double?
    public let latitude: Double?
    public let altitude: String?
}

public struct WeatherData: Codable {
    public let obsTime: String?          //观测时间
    public let altitude: String?         //海拔高度（米）
    public let temp: String?             //温度（摄氏度）
    public let feelsLike: String?        //体感温度（摄氏度）
    public let icon: String?             //天气图标代码
    public let text: String?             //天气状况文字描述
    public let wind360: String?          //风向360角度
    public let windDir: String?          //风向
    public let windScale: String?        //风力等级
    public let windSpeed: String?        //风速（公里/小时）
    public let humidity: String?         //相对湿度（百分比）
    public let precip: String?           //降水量（毫米）
    public let pressure: String?         //大气压强（百帕）
    public let vis: String?              //能见度（公里）
    public let cloud: String?            //云量（百分比）
    public let dewpublic: String?        //露点温度（摄氏度）
}


public struct EveryDayWeatherData: Codable {
    public let fxDate:String?           //预报日期
    public let sunrise:String?          //日出时间
    public let sunset:String?           //日落时间
    public let moonrise:String?         //月升时间
    public let moonset:String?          //月落时间
    public let moonPhase:String?        //月相名称
    public let moonPhaseIcon:String?    //月相图标代码
    public let tempMax:String?          //当天最高温度（摄氏度）
    public let tempMin:String?          //当天最低温度（摄氏度）
    public let iconDay:String?          //白天天气图标代码
    public let textDay:String?          //白天天气状况文字描述
    public let iconNight:String?        //夜间天气图标代码
    public let textNight:String?        //夜间天气状况文字描述
    public let wind360Day:String?       //白天风向360角度
    public let windDirDay:String?       //白天风向
    public let windScaleDay:String?     //白天风力等级
    public let windSpeedDay:String?     //白天风速（公里/小时）
    public let wind360Night:String?     //夜间风向360角度
    public let windDirNight:String?     //夜间风向
    public let windScaleNight:String?   //夜间风力等级
    public let windSpeedNight:String?   //夜间风速（公里/小时）
    public let humidity:String?         //相对湿度（百分比）
    public let precip:String?           //降水量（毫米）
    public let pressure:String?         //大气压强（百帕）
    public let vis:String?              //能见度（公里）
    public let cloud:String?            //云量（百分比）
    public let uvIndex: String?         //紫外线强度指数
}

public struct EveryHoursWeatherData: Codable {
    public let fxTime: String?          //预报时间
    public let temp: String?            //温度（摄氏度）
    public let icon: String?            //天气图标代码
    public let text: String?            //天气状况文字描述
    public let wind360: String?         //风向360角度
    public let windDir: String?         //风向
    public let windScale: String?       //风力等级
    public let windSpeed: String?       //风速（公里/小时）
    public let humidity: String?        //相对湿度（百分比）
    public let pop: String?             //降水概率（百分比）
    public let precip: String?          //降水量（毫米）
    public let pressure: String?        //大气压强（百帕）
    public let cloud: String?           //云量（百分比）
    public let dew: String?             //露点温度（摄氏度）
    
    // 提取小时部分 "06"
    var hourString: String? {
        guard let fxTime = fxTime, fxTime.count >= 11 else {
            return nil
        }
        // 从 "2025-12-06 06:00:00" 中提取 "06"
        let startIndex = fxTime.index(fxTime.startIndex, offsetBy: 11)
        let endIndex = fxTime.index(startIndex, offsetBy: 2)
        let hour = String(fxTime[startIndex..<endIndex])
        
        // 如果小时是 "00" 显示为 "00\n(今天)"
        if hour == "00" {
            return "00\n(今天)"
        }
        return hour
    }
}

public struct EveryHoursPrecipData: Codable {
    public let fxTime: String?         //预报时间
    public let precip: String?         //降水量
    
    // 转换为数值
    var precipValue: CGFloat {
        guard let precip = precip, let value = Double(precip) else {
            return 0
        }
        return CGFloat(value)
    }
    
    // 提取小时部分 "06"
    var hourString: String? {
        guard let fxTime = fxTime, fxTime.count >= 11 else {
            return nil
        }
        // 从 "2025-12-06 06:00:00" 中提取 "06"
        let startIndex = fxTime.index(fxTime.startIndex, offsetBy: 11)
        let endIndex = fxTime.index(startIndex, offsetBy: 2)
        let hour = String(fxTime[startIndex..<endIndex])
        
        // 如果小时是 "00" 显示为 "00\n(今天)"
        if hour == "00" {
            return "00\n(今天)"
        }
        return hour
    }
    
    // 是否是整点数据（用于减少X轴标签密度）
    var isHourly: Bool {
        guard let fxTime = fxTime, fxTime.count >= 14 else {
            return false
        }
        let minuteStart = fxTime.index(fxTime.startIndex, offsetBy: 14)
        let minuteEnd = fxTime.index(minuteStart, offsetBy: 2)
        let minute = String(fxTime[minuteStart..<minuteEnd])
        return minute == "00"
    }
    
    // 获取完整时间字符串
    var fullTimeString: String {
        guard let fxTime = fxTime else { return "未知时间" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "zh_CN")
        
        if let date = dateFormatter.date(from: fxTime) {
            let displayFormatter = DateFormatter()
            displayFormatter.locale = Locale(identifier: "zh_CN")
            displayFormatter.dateFormat = "MM/dd HH:mm"
            return displayFormatter.string(from: date)
        }
        return fxTime
    }
}

public struct WeatherWarningData: Codable {
    public let id: String?              //本条预警的唯一标识
    public let sender: String?          //预警发布单位
    public let pubTime: String?         //预警发布时间
    public let title: String?           //预警信息标题
    public let startTime: String?       //预警开始时间
    public let endTime: String?         //预警结束时间
    public let status: String?          //预警信息的发布状态
    public let severity: String?        //预警严重等级
    public let severityColor: String?   //预警严重等级颜色
    public let type: String?            //预警类型ID
    public let typeName: String?        //预警类型名称
    public let urgency: String?         //预警信息的紧迫程度
    public let certainty: String?       //预警信息的确定性
    public let text: String?            //预警详细文字描述
    public let related: String?         //与本条预警相关联的预警ID
}

public struct UserPOIData: Codable {
    public let poiId: String?
    public let id: String?
    public let name: String?
    public let description: String?
    public let lon: Double?
    public let lat: Double?
    public let category: Int?
    public let imgUrlList: [String]?
}
