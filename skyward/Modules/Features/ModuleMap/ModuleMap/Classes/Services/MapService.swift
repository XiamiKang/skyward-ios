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
        self.provider = NetworkProvider<MapAPI>()
    }
    
    // MARK: - 获取路线列表
    @available(iOS 13.0, *)
    public func getRouteList(_ model: RouteListModel) async throws -> Response {
        return try await provider.request(.getRouteList(model))
    }
    
    public func getRouteList(_ model: RouteListModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
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
    public func deleteRouteMsg(_ model: RouteMsgModel) async throws -> Response {
        return try await provider.request(.deleteRouteMsg(model))
    }
    
    public func deleteRouteMsg(_ model: RouteMsgModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.deleteRouteMsg(model), completion: completion)
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
    public func getWeatherMap() async throws -> Response {
        return try await provider.request(.getWeatherMap)
    }
    
    public func getWeatherMap(completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.getWeatherMap, completion: completion)
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
    public func saveUserRoute(_ model: UserRouteModel) async throws -> Response {
        return try await provider.request(.saveUserRoute(model))
    }
    
    public func saveUserRoute(_ model: UserRouteModel, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.saveUserRoute(model), completion: completion)
    }
    
    // MARK: - 保存轨迹
    @available(iOS 13.0, *)
    public func saveUserTrack(name: String, fileUrl: String)  async throws -> Response {
        return try await provider.request(.saveUserTrack(name: name, fileUrl: fileUrl))
    }
    
    public func saveUserTrack(name: String, fileUrl: String, completion: @escaping (Result<Response, MoyaError>) -> Void) {
        provider.request(.saveUserTrack(name: name, fileUrl: fileUrl), completion: completion)
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
}
