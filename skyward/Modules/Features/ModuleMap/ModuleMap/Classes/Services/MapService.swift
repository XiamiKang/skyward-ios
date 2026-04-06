//
//  MapService.swift
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

public class MapService {
    private let provider: NetworkProvider<MapAPI>
    
    public init() {
        self.provider = NetworkProvider<MapAPI>(plugins: [])
    }
    
    // MARK: - 获取路线列表
    @available(iOS 13.0, *)
    public func getRouteList(_ model: RouteListReq) async throws -> Response {
        return try await provider.request(.getRouteList(model))
    }
    
    public func getRouteList(_ model: RouteListReq, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getRouteList(model), completion: completion)
    }
    
    // MARK: - 获取路线详情
    @available(iOS 13.0, *)
    public func getRouteMsg(_ model: RouteMsgModel) async throws -> Response {
        return try await provider.request(.getRouteMsg(model))
    }
    
    public func getRouteMsg(_ model: RouteMsgModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getRouteMsg(model), completion: completion)
    }
    
    // MARK: - 删除路线
    @available(iOS 13.0, *)
    public func deleteRoute(_ routeId: String) async throws -> Response {
        return try await provider.request(.deleteRoute(routeId))
    }
    
    public func deleteRoute(_ routeId: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.deleteRoute(routeId), completion: completion)
    }
    
    public func deleteRoutes(_ routeIds: [String], completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.deleteRoutes(routeIds), completion: completion)
    }
    
    // MARK: - 更新路线
    public func updateRoute(params: [String : Any], completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.updateRoute(params: params), completion: completion)
    }
    
    // MARK: - 获取用户兴趣点列表
    @available(iOS 13.0, *)
    public func getUserPOIList(_ model: PublicPOIListModel) async throws -> Response {
        return try await provider.request(.getUserPOIList(model))
    }
    
    public func getUserPOIList(_ model: PublicPOIListModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getUserPOIList(model), completion: completion)
    }
    
    // MARK: - 获取用户兴趣点详情
    @available(iOS 13.0, *)
    public func getUserPOIData(_ id: String) async throws -> Response {
        return try await provider.request(.getUserPOIData(id))
    }
    
    public func getUserPOIData(_ id: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getUserPOIData(id), completion: completion)
    }
    
    // MARK: - 获取天气数据
    @available(iOS 13.0, *)
    public func getCityWeatherList() async throws -> Response {
        return try await provider.request(.getCityWeatherList)
    }
    
    public func getCityWeatherList(completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getCityWeatherList, completion: completion)
    }
    
    // MARK: - 搜索数据
    @available(iOS 13.0, *)
    public func getSearchData(_ addressName: String) async throws -> Response {
        return try await provider.request(.searchMapMsgWithAddressName(addressName))
    }
    
    public func getSearchData(_ addressName: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.searchMapMsgWithAddressName(addressName), completion: completion)
    }
    
    // MARK: - 根据经纬度获取位置数据
    @available(iOS 13.0, *)
    public func getPointData(_ location: String) async throws -> Response {
        return try await provider.request(.searchMapMsgWithLocation(location))
    }
    
    public func getPointData(_ location: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.searchMapMsgWithLocation(location), completion: completion)
    }
    
    // MARK: - 根据经纬度获取天气数据
    @available(iOS 13.0, *)
    public func getPointWeatherData(_ location: CLLocationCoordinate2D) async throws -> Response {
        return try await provider.request(.getPointWeatherData(location))
    }
    
    public func getPointWeatherData(_ location: CLLocationCoordinate2D, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getPointWeatherData(location), completion: completion)
    }
    
    // MARK: - 保存兴趣点
    @available(iOS 13.0, *)
    public func saveUserPOI(_ model: UserPOIModel) async throws -> Response {
        return try await provider.request(.saveUserPOI(model))
    }
    
    public func saveUserPOI(_ model: UserPOIModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.saveUserPOI(model), completion: completion)
    }
    
    // MARK: - 保存路线
    @available(iOS 13.0, *)
    public func saveUserRoute(params: [String : Any]) async throws -> Response {
        return try await provider.request(.saveUserRoute(params: params))
    }
    
    public func saveUserRoute(params: [String : Any], completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.saveUserRoute(params: params), completion: completion)
    }
    
    // MARK: - 获取天气信息
    public func getWeatherInfo(_ location: CLLocationCoordinate2D, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getWeatherInfo(location), completion: completion)
    }
    
    // MARK: - 获取天气预警
    @available(iOS 13.0, *)
    public func getWeatherWarningMsg(_ location: CLLocationCoordinate2D) async throws -> Response {
        return try await provider.request(.getWeatherWarningMsg(location))
    }
    
    public func getWeatherWarningMsg(_ location: CLLocationCoordinate2D, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getWeatherWarningMsg(location), completion: completion)
    }
    
    // MARK: - 获取每小时的天气预报
    @available(iOS 13.0, *)
    public func getEveryHoursWeatherMsg(_ location: CLLocationCoordinate2D) async throws -> Response {
        return try await provider.request(.getEveryHoursWeatherMsg(location))
    }
    
    public func getEveryHoursWeatherMsg(_ location: CLLocationCoordinate2D, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getEveryHoursWeatherMsg(location), completion: completion)
    }
    
    // MARK: - 获取每小时的降水量
    @available(iOS 13.0, *)
    public func getEveryHoursPrecipMsg(_ location: CLLocationCoordinate2D) async throws -> Response {
        return try await provider.request(.getEveryHoursPrecipMsg(location))
    }
    
    public func getEveryHoursPrecipMsg(_ location: CLLocationCoordinate2D, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getEveryHoursPrecipMsg(location), completion: completion)
    }
    
    // MARK: - 每日天气预报
    @available(iOS 13.0, *)
    public func getEveryDayWeatherMsg(_ location: CLLocationCoordinate2D) async throws -> Response {
        return try await provider.request(.getEveryDayWeatherMsg(location))
    }
    
    public func getEveryDayWeatherMsg(_ location: CLLocationCoordinate2D, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getEveryDayWeatherMsg(location), completion: completion)
    }
    
    // MARK: - 删除用户兴趣点
    @available(iOS 13.0, *)
    public func deleteUserPOIData(_ id: String) async throws -> Response {
        return try await provider.request(.deleteUserPOIData(id))
    }
    
    public func deleteUserPOIData(_ id: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.deleteUserPOIData(id), completion: completion)
    }
    
    // MARK: - 敏感词校验
    public func checkSensitiveWords(_ content: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.checkSensitiveWords(content), completion: completion)
    }
    
    // MARK: - 收藏公共兴趣点
    @available(iOS 13.0, *)
    public func collectPublicPOI(_ poiId: String) async throws -> Response {
        return try await provider.request(.collectPublicPOI(poiId))
    }
    
    public func collectPublicPOI(_ poiId: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.collectPublicPOI(poiId), completion: completion)
    }
    
    // MARK: - 打卡公共兴趣点
    @available(iOS 13.0, *)
    public func checkInPublicPOI(_ poiId: String) async throws -> Response {
        return try await provider.request(.checkInPublicPOI(poiId))
    }
    
    public func checkInPublicPOI(_ poiId: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.checkInPublicPOI(poiId), completion: completion)
    }
    
    // MARK: - 取消收藏公共兴趣点
    @available(iOS 13.0, *)
    public func cancelCollectPublicPOI(_ poiId: String) async throws -> Response {
        return try await provider.request(.cancelCollectPublicPOI(poiId))
    }
    
    public func cancelCollectPublicPOI(_ poiId: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.cancelCollectPublicPOI(poiId), completion: completion)
    }
    
    // MARK: - 取消打卡公共兴趣点
    @available(iOS 13.0, *)
    public func cancelCheckInPublicPOI(_ poiId: String) async throws -> Response {
        return try await provider.request(.cancelCheckInPublicPOI(poiId))
    }
    
    public func cancelCheckInPublicPOI(_ poiId: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.cancelCheckInPublicPOI(poiId), completion: completion)
    }
    
    // MARK: - 更新兴趣点
    @available(iOS 13.0, *)
    public func updateUserPOI(_ model: UserPOIModel) async throws -> Response {
        return try await provider.request(.updateUserPOI(model))
    }
    
    public func updateUserPOI(_ model: UserPOIModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.updateUserPOI(model), completion: completion)
    }
}
