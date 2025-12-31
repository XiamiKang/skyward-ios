//
//  MapViewModel.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/3.
//

import Foundation
import Combine
import CoreLocation
import Moya
import SWKit

public enum SearchType {
    case coordinate  // 坐标格式
    case keyword     // 关键字格式（汉字、地址等）
}

public class MapViewModel: ObservableObject {
    
    // MARK: - 依赖
    private let mapService = MapService()
    private let locationManager = LocationManager()
    
    // MARK: - 输出属性（使用 @Published 直接定义）
    @Published public var routeListData: RouteListData?
    @Published public var userPoiListData: [UserPOIData]?
    @Published public var weatherData: WeatherAPIResponse?
    @Published public var customPointData: [MapSearchPointMsgData]?
    @Published public var error: MapError?
    @Published public var isLoading = false
    
    // MARK: - 输入
    public struct Input {
        let routeListRequest = PassthroughSubject<RouteListModel, Never>()
        let userPoiListRequest = PassthroughSubject<PublicPOIListModel, Never>()
        let weatherRequest = PassthroughSubject<Void, Never>()
        let locationRequest = PassthroughSubject<Void, Never>()
        let customPointRequest = PassthroughSubject<String, Never>()
    }
    
    // MARK: - 属性
    public let input = Input()
    public var cancellables = Set<AnyCancellable>()
    
    // MARK: - POI管理
    @Published public var selectedPOI: PublicPOIData?
    @Published public var visiblePOIs: [PublicPOIData] = []
    
    // MARK: - 初始化
    public init() {
        bind()
    }
    
    // MARK: - 绑定
    private func bind() {
        // 绑定路线列表请求
        input.routeListRequest
            .flatMap { [weak self] model -> AnyPublisher<RouteListData, MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放")).eraseToAnyPublisher()
                }
                return self.fetchRouteList(model: model)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.routeListData = data
            }
            .store(in: &cancellables)
        
        // 绑定POI列表请求
        input.userPoiListRequest
            .flatMap { [weak self] model -> AnyPublisher<[UserPOIData], MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放")).eraseToAnyPublisher()
                }
                return self.fetchUserPoiList(model: model)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.userPoiListData = data
            }
            .store(in: &cancellables)
        
        // 绑定天气请求
        input.weatherRequest
            .flatMap { [weak self] _ -> AnyPublisher<WeatherAPIResponse, MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放")).eraseToAnyPublisher()
                }
                return self.fetchWeatherData()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.weatherData = data
            }
            .store(in: &cancellables)
        
        // 绑定地图点信息
        input.customPointRequest
            .flatMap { [weak self] location -> AnyPublisher<[MapSearchPointMsgData], MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放")).eraseToAnyPublisher()
                }
                return self.mapPointData(location)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.customPointData = data
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 天气数据解析
    private func parseWeatherResponse(_ responseData: Data) throws -> WeatherAPIResponse {
        do {
            let baseResponse = try JSONDecoder().decode(WeatherBaseResponse.self, from: responseData)
            
            guard baseResponse.code == "00000" else {
                throw MapError.businessError(message: baseResponse.msg, code: baseResponse.code)
            }
            
            switch baseResponse.parseWeatherData() {
            case .success(let weatherResponse):
                print("✅ 天气数据解析成功")
                logWeatherData(weatherResponse)
                return weatherResponse
                
            case .failure(let error):
                throw error
            }
            
        } catch let decodingError as DecodingError {
            print("❌ JSON解码错误: \(decodingError)")
            throw MapError.parseError("数据格式错误")
        }
    }
    
    // MARK: - 实用方法
    public func getWeatherData(for type: String) -> WeatherLayerData? {
        guard let response = weatherData else { return nil }
        
        switch type {
        case "温度":
            return response.TEM
        case "湿度":
            return response.RHU
        case "风速":
            return response.WINS
        case "能见度":
            return response.VIS
        default:
            return nil
        }
    }
    
    public func getWeatherImageURL(for type: String) -> URL? {
        guard let weatherData = getWeatherData(for: type),
              let url = URL(string: weatherData.imgurl) else {
            return nil
        }
        return url
    }
    
    public func getLegendImageURL(for type: String) -> URL? {
        guard let weatherData = getWeatherData(for: type),
              let url = URL(string: weatherData.tuliurl) else {
            return nil
        }
        return url
    }
    
    public func getAvailableWeatherTypes() -> [String] {
        guard let response = weatherData else { return [] }
        
        var types: [String] = []
        if response.TEM != nil { types.append("温度") }
        if response.RHU != nil { types.append("湿度") }
        if response.WINS != nil { types.append("风速") }
        if response.VIS != nil { types.append("能见度") }
        return types
    }
    
    // MARK: - 日志记录
    private func logWeatherData(_ weatherResponse: WeatherAPIResponse) {
        print("\n🌤️ ========== 天气数据详情 ==========")
        
        if let temperature = weatherResponse.TEM {
            print("🌡️ 温度数据:")
            print("   图片URL: \(temperature.imgurl)")
            print("   图例URL: \(temperature.tuliurl)")
        }
        
        if let humidity = weatherResponse.RHU {
            print("💧 湿度数据:")
            print("   图片URL: \(humidity.imgurl)")
        }
        
        if let windSpeed = weatherResponse.WINS {
            print("💨 风速数据:")
            print("   图片URL: \(windSpeed.imgurl)")
        }
        
        if let visibility = weatherResponse.VIS {
            print("👁️ 能见度数据:")
            print("   图片URL: \(visibility.imgurl)")
        }
        
        print("===================================\n")
    }
    
    
    private func displayPOIsOnMap(_ pois: [PublicPOIData]) {
        print("----------添加兴趣点----------")
        // 更新可见POI列表
        visiblePOIs = pois
    }
    
    public func determineSearchType(_ input: String) -> SearchType {
        // 去除空格
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        
        // 判断是否为坐标格式（经度,纬度）
        let coordinatePattern = "^[-+]?\\d{1,3}(\\.\\d+)?\\s*,\\s*[-+]?\\d{1,2}(\\.\\d+)?$"
        
        if let range = trimmed.range(of: coordinatePattern, options: .regularExpression) {
            // 验证坐标数值范围（可选）
            let parts = trimmed.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            
            if parts.count == 2,
               let longitude = Double(parts[0]),
               let latitude = Double(parts[1]),
               longitude >= -180 && longitude <= 180,
               latitude >= -90 && latitude <= 90 {
                return .coordinate
            }
        }
        
        return .keyword
    }

    
}

// MARK: - 网络请求
extension MapViewModel {
    // 
    private func fetchRouteList(model: RouteListModel) -> AnyPublisher<RouteListData, MapError> {
        isLoading = true
        
        return Future<RouteListData, MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getRouteList(model) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<RouteListData>.self, from: response.data)
                            
                            if baseResponse.success, let data = baseResponse.data {
                                promise(.success(data))
                            } else {
                                promise(.failure(.businessError(
                                    message: baseResponse.msg,
                                    code: baseResponse.code
                                )))
                            }
                        } catch {
                            promise(.failure(.parseError("数据解析失败")))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    // MARK: - 地图天气图层数据
    private func fetchWeatherData() -> AnyPublisher<WeatherAPIResponse, MapError> {
        isLoading = true
        
        return Future<WeatherAPIResponse, MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getWeatherMap { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let weatherResponse = try self.parseWeatherResponse(response.data)
                            promise(.success(weatherResponse))
                        } catch let error as MapError {
                            promise(.failure(error))
                        } catch {
                            promise(.failure(.parseError("未知解析错误")))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 用户兴趣点
    private func fetchUserPoiList(model: PublicPOIListModel) -> AnyPublisher<[UserPOIData], MapError> {
        isLoading = true
        
        return Future<[UserPOIData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getUserPOIList(model) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[UserPOIData]>.self, from: response.data)
                            
                            if baseResponse.success, let data = baseResponse.data {
                                promise(.success(data))
                            } else {
                                promise(.failure(.businessError(
                                    message: baseResponse.msg,
                                    code: baseResponse.code
                                )))
                            }
                        } catch {
                            promise(.failure(.parseError("数据解析失败")))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 用户兴趣点详情
    public func fetchUserPoiData(id: String) -> AnyPublisher<UserPOIData, MapError> {
        isLoading = true
        
        return Future<UserPOIData, MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getUserPOIData(id) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<UserPOIData>.self, from: response.data)
                            
                            if baseResponse.success, let data = baseResponse.data {
                                promise(.success(data))
                            } else {
                                promise(.failure(.businessError(
                                    message: baseResponse.msg,
                                    code: baseResponse.code
                                )))
                            }
                        } catch {
                            promise(.failure(.parseError("数据解析失败")))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 地图搜索
    public func mapSearchData(address addressName: String) -> AnyPublisher<[MapSearchPointMsgData], MapError> {
        isLoading = true
        
        return Future<[MapSearchPointMsgData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getSearchData(addressName) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[MapSearchPointMsgData]>.self, from: response.data)
                            
                            if baseResponse.success {
                                if let data = baseResponse.data {
                                    // 判断数组是否为空
                                    if data.isEmpty {
                                        // 返回空数组的情况
                                        promise(.success([]))
                                    } else {
                                        // 返回有数据的数组
                                        promise(.success(data))
                                    }
                                } else {
                                    // data 为 nil，也视为空数组
                                    promise(.success([]))
                                }
                            } else {
                                promise(.failure(.businessError(
                                    message: baseResponse.msg,
                                    code: baseResponse.code
                                )))
                            }
                        } catch {
                            promise(.failure(.parseError("数据解析失败")))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    // MARK: - 地图点位信息
    public func mapPointData(_ location: String) -> AnyPublisher<[MapSearchPointMsgData], MapError> {
        isLoading = true
        
        return Future<[MapSearchPointMsgData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getPointData(location) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[MapSearchPointMsgData]>.self, from: response.data)
                            
                            if baseResponse.success, let data = baseResponse.data {
                                promise(.success(data))
                            } else {
                                promise(.failure(.businessError(
                                    message: baseResponse.msg,
                                    code: baseResponse.code
                                )))
                            }
                        } catch {
                            promise(.failure(.parseError("数据解析失败")))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    // MARK: - 保存自定义兴趣点
    public func saveUserPoi(_ model: UserPOIModel) -> AnyPublisher<UserPOIData, MapError> {
        isLoading = true
        
        return Future<UserPOIData, MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.saveUserPOI(model) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<UserPOIData>.self, from: response.data)
                            
                            if baseResponse.success, let data = baseResponse.data {
                                promise(.success(data))
                            } else {
                                promise(.failure(.businessError(
                                    message: baseResponse.msg,
                                    code: baseResponse.code
                                )))
                            }
                        } catch {
                            promise(.failure(.parseError("数据解析失败")))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 删除自定义兴趣点
    public func deleteUserPoi(_ id: String) -> AnyPublisher<Bool, MapError> {
        isLoading = true
        
        return Future<Bool, MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.deleteUserPOIData(id) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<Bool>.self, from: response.data)
                            
                            if baseResponse.success, let data = baseResponse.data {
                                promise(.success(data))
                            } else {
                                promise(.failure(.businessError(
                                    message: baseResponse.msg,
                                    code: baseResponse.code
                                )))
                            }
                        } catch {
                            promise(.failure(.parseError("数据解析失败")))
                        }
                        
                    case .failure(let error):
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    public func openAmapNavigation(startLat: Double, startLon: Double,
                           endLat: Double, endLon: Double,
                           destinationName: String) {
        let urlString = "iosamap://path?sourceApplication=skyward&sid=BGVIS1&slat=\(startLat)&slon=\(startLon)&sname=我的位置&did=BGVIS2&dlat=\(endLat)&dlon=\(endLon)&dname=\(destinationName)&dev=0&t=0"
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            // 未安装高德地图，跳转App Store下载
            let appStoreURL = URL(string: "https://apps.apple.com/cn/app/id461703208")!
            UIApplication.shared.open(appStoreURL)
        }
    }

}

