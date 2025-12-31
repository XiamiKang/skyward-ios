//
//  APIEnums.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import SWNetwork
import Moya
import Combine
import CoreLocation
import SWKit

public enum MapAPI {
    case getRouteList(_ model: RouteListModel)                            // 获取用户路线列表
    case getRouteMsg(_ model: RouteMsgModel)                              // 获取路线详情
    case deleteRouteMsg(_ model: RouteMsgModel)                           // 删除路线
    case getWeatherMap                                                    // 获取天气地图
    case searchMapMsgWithAddressName(_ address: String)                   // 搜索--通过地名
    case searchMapMsgWithLocation(_ location: String)                     // 搜索--通过经纬度
    case getPointWeatherData(_ location: CLLocationCoordinate2D)          // 获取点击位置的天气信息
    case saveUserPOI(_ model: UserPOIModel)                               // 保存兴趣点
    case saveUserRoute(_ model: UserRouteModel)                           // 保存路线
    case saveUserTrack(name: String, fileUrl: String)                     // 保存轨迹
    case getWeatherWarningMsg(_ location: CLLocationCoordinate2D)         // 获取天气预警信息
    case getEveryHoursWeatherMsg(_ location: CLLocationCoordinate2D)      // 获取每小时天气信息
    case getEveryHoursPrecipMsg(_ location: CLLocationCoordinate2D)       // 获取每小时降水量
    case getEveryDayWeatherMsg(_ location: CLLocationCoordinate2D)        // 获取每日天气预报
    case getUserPOIList(_ model: PublicPOIListModel)                      // 获取用户兴趣点列表
    case getUserPOIData(_ id: String)                                     // 获取用户兴趣点详情
    case deleteUserPOIData(_ id: String)                                  // 删除用户兴趣点
}

extension MapAPI: NetworkAPI {

    public var path: String {
        switch self {
        case .getRouteList:
            return "/txts-user-center-app/api/v1/user-route/page/list"
        case .getRouteMsg:
            return "/txts-user-center-app/api/v1/user-route/info"
        case .deleteRouteMsg:
            return "/txts-user-center-app/api/v1/user-route"
        case .getWeatherMap:
            return "/txts-data-app/api/v1/data/map/decision"
        case .searchMapMsgWithAddressName:
            return "/txts-data-app/api/v1/data/map/parse/address"
        case .searchMapMsgWithLocation:
            return "/txts-data-app/api/v1/data/map/parse/address"
        case .getPointWeatherData:
            return "/txts-data-app/api/v1/data/weather/current"
        case .saveUserPOI:
            return "/txts-user-center-app/api/v1/user-point-position/save"
        case .saveUserRoute, .saveUserTrack:
            return "/txts-user-center-app/api/v1/user-route/save"
        case .getWeatherWarningMsg:
            return "/txts-data-app/api/v1/data/weather/warning"
        case .getEveryHoursWeatherMsg:
            return "/txts-data-app/api/v1/data/weather/hourly"
        case .getEveryHoursPrecipMsg:
            return "/txts-data-app/api/v1/data/weather/hourly/precip"
        case .getEveryDayWeatherMsg:
            return "/txts-data-app/api/v1/data/weather/daily"
        case .getUserPOIList:
            return "/txts-user-center-app/api/v1/user-point-position/list"
        case .getUserPOIData:
            return "/txts-user-center-app/api/v1/user-point-position/getDetail"
        case .deleteUserPOIData:
            return "/txts-user-center-app/api/v1/user-point-position/remove"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case    .getWeatherMap,
                .searchMapMsgWithLocation,
                .searchMapMsgWithAddressName,
                .getPointWeatherData,
                .getWeatherWarningMsg,
                .getEveryHoursWeatherMsg,
                .getEveryHoursPrecipMsg,
                .getEveryDayWeatherMsg,
                .getUserPOIData:
            return .get
        case .getRouteList,
             .getRouteMsg,
             .saveUserPOI,
             .saveUserRoute,
             .saveUserTrack,
             .getUserPOIList:
            return .post
        case .deleteRouteMsg,
             .deleteUserPOIData:
            return .delete
        }
    }
    
    public var task: Task {
        switch self {
        case .getRouteList(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .getRouteMsg(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .deleteRouteMsg(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .getWeatherMap:
            return .requestPlain
        case .searchMapMsgWithAddressName(let address):
            return .requestParameters(
                parameters: ["address": address],
                encoding: URLEncoding.default
            )
        case .searchMapMsgWithLocation(let location):
            return .requestParameters(
                parameters: ["location": location],
                encoding: URLEncoding.default
            )
        case .getPointWeatherData(let location):
            return .requestParameters(
                parameters: ["longitude": "\(location.longitude)",
                             "latitude": "\(location.latitude)"],
                encoding: URLEncoding.default
            )
        case .saveUserPOI(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .saveUserRoute(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .saveUserTrack(let name, let fileUrl):
            return .requestParameters(
                parameters: ["routeName": name,
                             "fileUrl": fileUrl,
                             "type": 1],
                encoding: JSONEncoding.default
            )
        case .getWeatherWarningMsg(let location):
            return .requestParameters(
                parameters: ["longitude": "\(location.longitude)",
                             "latitude": "\(location.latitude)"],
                encoding: URLEncoding.default
            )
        case .getEveryHoursWeatherMsg(let location):
            return .requestParameters(
                parameters: ["hours":24,
                             "longitude": "\(location.longitude)",
                             "latitude": "\(location.latitude)"],
                encoding: URLEncoding.default
            )
        case .getEveryHoursPrecipMsg(let location):
            return .requestParameters(
                parameters: ["hours":24,
                             "longitude": "\(location.longitude)",
                             "latitude": "\(location.latitude)"],
                encoding: URLEncoding.default
            )
        case .getEveryDayWeatherMsg(let location):
            return .requestParameters(
                parameters: ["days":7,
                             "longitude": "\(location.longitude)",
                             "latitude": "\(location.latitude)"],
                encoding: URLEncoding.default
            )
        case .getUserPOIList(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .getUserPOIData(let id):
            return .requestParameters(
                parameters: ["id": id],
                encoding: URLEncoding.default
            )
        case .deleteUserPOIData(let id):
            return .requestParameters(
                parameters: ["id": id],
                encoding: URLEncoding.default
            )
        }
    }
    
    public var headers: [String: String]? {
        var headers = ["Content-Type": "application/json"]
        
        if let token = TokenManager.shared.accessToken {
            headers["Authorization"] = "Bearer \(token)"
        }
        
        return headers
    }
}
