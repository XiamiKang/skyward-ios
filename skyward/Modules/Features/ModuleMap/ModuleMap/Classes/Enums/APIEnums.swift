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
    case getRouteList(_ model: RouteListReq)                              // 获取用户路线列表
    case getRouteMsg(_ model: RouteMsgModel)                              // 获取路线详情
    case saveUserRoute(params: [String : Any])                            // 保存路线
    case deleteRoute(_ routeId: String)                                   // 删除路线
    case deleteRoutes(_ routeIds: [String])                               // 删除路线
    case updateRoute(params: [String : Any])                              // 更改路线
    case searchMapMsgWithAddressName(_ address: String)                   // 搜索--通过地名
    case searchMapMsgWithLocation(_ location: String)                     // 搜索--通过经纬度
    case getPointWeatherData(_ location: CLLocationCoordinate2D)          // 获取点击位置的天气信息
    case saveUserPOI(_ model: UserPOIModel)                               // 保存兴趣点
    case getWeatherWarningMsg(_ location: CLLocationCoordinate2D)         // 获取天气预警信息
    case getWeatherInfo(_ location: CLLocationCoordinate2D)               // 获取天气信息
    case getEveryHoursWeatherMsg(_ location: CLLocationCoordinate2D)      // 获取每小时天气信息
    case getEveryHoursPrecipMsg(_ location: CLLocationCoordinate2D)       // 获取每小时降水量
    case getEveryDayWeatherMsg(_ location: CLLocationCoordinate2D)        // 获取每日天气预报
    case getUserPOIList(_ model: PublicPOIListModel)                      // 获取用户兴趣点列表
    case getUserPOIData(_ id: String)                                     // 获取用户兴趣点详情
    case deleteUserPOIData(_ id: String)                                  // 删除用户兴趣点
    case checkSensitiveWords(_ content: String)                           // 敏感词校验
    case collectPublicPOI(_ poiId: String)                                // 公共兴趣点收藏
    case checkInPublicPOI(_ poiId: String)                                // 公共兴趣点打卡
    case cancelCollectPublicPOI(_ poiId: String)                          // 公共兴趣点取消收藏
    case cancelCheckInPublicPOI(_ poiId: String)                          // 公共兴趣点取消打卡
    case getCityWeatherList                                               // 获取城市天气列表
    case updateUserPOI(_ model: UserPOIModel)                             // 更新兴趣点
}

extension MapAPI: NetworkAPI {

    public var path: String {
        switch self {
        case .getRouteList:
            return "/txts-user-center-app/api/v1/user-route/page/list"
        case .getRouteMsg:
            return "/txts-user-center-app/api/v1/user-route/info"
        case .saveUserRoute:
            return "/txts-user-center-app/api/v1/user-route/save"
        case .deleteRoute:
            return "/txts-user-center-app/api/v1/user-route"
        case .deleteRoutes:
            return "/txts-user-center-app/api/v1/user-route/batchDelete"
        case .updateRoute:
            return "/txts-user-center-app/api/v1/user-route/update"
        case .searchMapMsgWithAddressName:
            return "/txts-data-app/api/v1/data/map/parse/address"
        case .searchMapMsgWithLocation:
            return "/txts-data-app/api/v1/data/map/parse/address"
        case .getPointWeatherData:
            return "/txts-data-app/api/v1/data/weather/current"
        case .saveUserPOI:
            return "/txts-user-center-app/api/v1/user-point-position/save"
        case .getWeatherInfo:
            return "/txts-data-app/api/v1/data/weather/current"
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
        case .checkSensitiveWords:
            return "/txts-system/api/v1/sensitive-words/check"
        case .collectPublicPOI(let poiId):
            return "/txts-user-center-app/api/v1/user-favorites/poi/\(poiId)"
        case .checkInPublicPOI(let poiId):
            return "/txts-user-center-app/api/v1/point-check/add/check/\(poiId)"
        case .cancelCollectPublicPOI(let poiId):
            return "/txts-user-center-app/api/v1/user-favorites/cancel/\(poiId)/0"
        case .cancelCheckInPublicPOI(let poiId):
            return "/txts-user-center-app/api/v1/point-check/cancel/check/\(poiId)"
        case .getCityWeatherList:
            return "/txts-data-app/api/v1/data/map/city/temperatureList"
        case .updateUserPOI:
            return "/txts-user-center-app/api/v1/user-point-position/update"
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case    .getRouteList,
                .searchMapMsgWithLocation,
                .searchMapMsgWithAddressName,
                .getPointWeatherData,
                .getWeatherInfo,
                .getWeatherWarningMsg,
                .getEveryHoursWeatherMsg,
                .getEveryHoursPrecipMsg,
                .getEveryDayWeatherMsg,
                .getUserPOIData,
                .checkSensitiveWords,
                .checkInPublicPOI,
                .getCityWeatherList:
            return .get
        case .getRouteMsg,
             .saveUserPOI,
             .saveUserRoute,
             .deleteRoutes,
             .updateRoute,
             .getUserPOIList,
             .collectPublicPOI:
            return .post
        case .deleteRoute,
             .deleteUserPOIData,
             .cancelCollectPublicPOI,
             .cancelCheckInPublicPOI:
            return .delete
        case .updateUserPOI:
            return .put
        }
    }
    
    public var task: Task {
        switch self {
        case .getRouteList(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: URLEncoding.default
            )
        case .getRouteMsg(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
            )
        case .deleteRoute(let routeId):
            return .requestParameters(
                parameters: ["routeId": routeId],
                encoding: URLEncoding.default
            )
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
        case .saveUserRoute(let params), .updateRoute(params: let params):
            return .requestParameters(
                parameters: params,
                encoding: JSONEncoding.default
            )
        case .deleteRoutes(let routeIds):
            // 后端只需要 [ids] 数组，不需要 key:"routeIds"
            // 直接发送 JSON 数组: ["id1", "id2", ...]
            if let data = try? JSONEncoder().encode(routeIds) {
                return .requestData(data)
            }
            return .requestPlain
        case .getWeatherInfo(let location), .getWeatherWarningMsg(let location):
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
        case .checkSensitiveWords(let content):
            return .requestParameters(
                parameters: ["content": content],
                encoding: URLEncoding.default
            )
        case .collectPublicPOI( _):
            return .requestPlain
        case .checkInPublicPOI( _):
            return .requestPlain
        case .cancelCollectPublicPOI( _):
            return .requestPlain
        case .cancelCheckInPublicPOI( _):
            return .requestPlain
        case .getCityWeatherList:
            return .requestPlain
        case .updateUserPOI(let model):
            return .requestParameters(
                parameters: model.toDictionary(),
                encoding: JSONEncoding.default
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
