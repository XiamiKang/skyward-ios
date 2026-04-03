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
import SWNetwork

public enum SearchType {
    case coordinate  // 坐标格式
    case keyword     // 关键字格式（汉字、地址等）
}

public class MapViewModel: ObservableObject {
    
    // MARK: - 依赖
    private let mapService = MapService()
    private let locationManager = LocationManager()
    private let uploadService = UploadManager()
    
    // MARK: - 输出属性（使用 @Published 直接定义）
    @Published public var routeListData: [RouteData]?
    @Published public var userPoiListData: [UserPOIData]?
    @Published public var weatherData: [CityWeatherData]?
    @Published public var customPointData: [MapSearchPointMsgData]?
    @Published public var error: MapError?
    @Published public var isLoading = false
    
    // MARK: - 输入
    public struct Input {
        let routeListRequest = PassthroughSubject<RouteListReq, Never>()
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
            .flatMap { [weak self] model -> AnyPublisher<[RouteData], MapError> in
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
                return self.fetchAndSaveUserPoiList(model: model)
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
            .flatMap { [weak self] _ -> AnyPublisher<[CityWeatherData], MapError> in
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
    
    // MARK: - 实用方法
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

    func loadWeatherInfo(completion: @escaping (WeatherInfo) -> Void) {
        // 首先通过路由检查 HomeViewModel 是否已有天气信息
        SWRouter.handle(RouteTable.homeWeatherInfoUrl, callback: { [weak self] result in
            if let weatherInfo = result as? WeatherInfo {
                // HomeViewModel 已有天气信息，直接使用
                completion(weatherInfo)
            } else {
                // HomeViewModel 没有天气信息，发起网络请求
                self?.fetchWeatherInfo(completion: completion)
            }
        })
    }
}

// MARK: - 网络请求
extension MapViewModel {

    private func fetchWeatherInfo(completion: @escaping (WeatherInfo) -> Void) {
        let locationManager = LocationManager()
        locationManager.getCurrentLocation { [weak self] location, error in
            guard let location = location else {
                return
            }

            var districtName = ""
            var weatherInfo: WeatherInfo?

            let group = DispatchGroup()
            group.enter()
            LocationManager.reverseGeocode(location: location) { placemark in
                if let district = placemark?.subLocality {
                    districtName = district
                }
                group.leave()
            }

            group.enter()
            self?.mapService.getWeatherInfo(location.coordinate) { result in
                group.leave()
                if case .success(let rsp) = result {
                    do {
                        let networkResponse = try rsp.map(NetworkResponse<WeatherInfo>.self)
                        weatherInfo = networkResponse.data
                    } catch {

                    }
                }
            }

            group.notify(queue: .main) {
                weatherInfo?.district = districtName
                if let weatherInfo = weatherInfo {
                    completion(weatherInfo)
                }
            }
        }
    }

    //
    private func fetchRouteList(model: RouteListReq) -> AnyPublisher<[RouteData], MapError> {
        isLoading = true
        
        return Future<[RouteData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getRouteList(model) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[RouteData]>.self, from: response.data)
                            
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
    // MARK: - 城市天气数据
    private func fetchWeatherData() -> AnyPublisher<[CityWeatherData], MapError> {
        isLoading = true
        
        return Future<[CityWeatherData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getCityWeatherList { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let weatherResponse = try JSONDecoder().decode(BaseResponse<[CityWeatherData]>.self, from: response.data)
                            
                            if weatherResponse.success, let data = weatherResponse.data {
                                promise(.success(data))
                                
                                CityWeatherDBManager.shared.deleteAllCityWeathers()
                                CityWeatherDBManager.shared.batchInsertCityWeathers(data)
                            } else {
                                promise(.failure(.businessError(
                                    message: weatherResponse.msg,
                                    code: weatherResponse.code
                                )))
                            }
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
                                print("网络保存兴趣点---\(data)")
                                self.updateUserPoiDetailToLocal(data, oldPoiId: model.poiId)
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
    
    // MARK: - 更新自定义兴趣点
    public func updateUserPoi(_ model: UserPOIModel) -> AnyPublisher<Bool, MapError> {
        isLoading = true
        
        return Future<Bool, MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.updateUserPOI(model) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<Bool>.self, from: response.data)
                            
                            if baseResponse.success, let data = baseResponse.data {
                                print("网络更新兴趣点---\(data)")
//                                self.updateUserPoiDetailToLocal(data, oldPoiId: model.poiId)
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
    

}

// MARK: - 本地数据库存储方法
extension MapViewModel {
    
    /// 获取网络数据并写入本地数据库
    /// - Parameter model: 请求参数模型
    /// - Returns: 包含网络数据的Publisher
    func fetchAndSaveUserPoiList(model: PublicPOIListModel) -> AnyPublisher<[UserPOIData], MapError> {
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
                            
                            if baseResponse.success, let networkData = baseResponse.data {
                                // 将网络数据保存到本地数据库
                                self.saveUserPoiListToLocal(networkData)
                                
                                // 返回网络数据供UI使用
                                promise(.success(networkData))
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
    
    /// 将网络POI数据保存到本地数据库
    /// - Parameter networkData: 网络获取的POI数据数组
    private func saveUserPoiListToLocal(_ networkData: [UserPOIData]) {
        // 使用DispatchQueue.global()替代Task
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            var localDataList: [UserPOILocalData] = []
            
            // 遍历网络数据，转换为本地数据模型
            for poiData in networkData {
                
                let altitudeDouble = poiData.altitude.flatMap { Double($0) }
                
                var localData = UserPOILocalData(
                    poiId: poiData.poiId,
                    name: poiData.name,
                    address: poiData.address,
                    description: poiData.description,
                    lon: poiData.lon,
                    lat: poiData.lat,
                    category: poiData.category,
                    imageData1: "",
                    imageData2: "",
                    imageData3: "",
                    isDelected: false,
                    isHide: false,
                    altitude: altitudeDouble,
                    isSynchronousNetwork: true // 来自网络的数据，标记为已同步
                )
                
                if let imgUrlList = poiData.imgUrlList {
                    for (index, imageUrl) in imgUrlList.enumerated() {
                        if index == 0 {
                            localData.imageData1 = imageUrl
                        }
                        if index == 1 {
                            localData.imageData2 = imageUrl
                        }
                        if index == 2 {
                            localData.imageData3 = imageUrl
                        }
                    }
                }
                
                localDataList.append(localData)
            }
            
            // 批量写入数据库（只添加不存在的，已存在的跳过）
            let newCount = UserPOILocalDBManager.shared.insertOrUpdateNetworkData(poiDatas: localDataList)
            
            print("📥 网络POI数据存储完成: 总计 \(networkData.count) 条, 新增 \(newCount) 条")
            
            // 更新同步管理器状态
            POISyncManager.shared.checkUnsyncedStatus()
            
            // 重新加载本地数据
            self.loadLocalUserPOI()
        }
    }
    
    /// 下载图片（支持0-3张）- 使用回调方式
    /// - Parameters:
    ///   - urlList: 图片URL列表
    ///   - completion: 完成回调，返回三个图片Data（可能为nil）
    private func downloadImages(from urlList: [String]?, completion: @escaping (Data?, Data?, Data?) -> Void) {
        guard let urlList = urlList, !urlList.isEmpty else {
            completion(nil, nil, nil)
            return
        }
        
        let count = min(urlList.count, 3)
        var imageData1: Data? = nil
        var imageData2: Data? = nil
        var imageData3: Data? = nil
        let dispatchGroup = DispatchGroup()
        
        for i in 0..<count {
            dispatchGroup.enter()
            
            guard let url = URL(string: urlList[i]) else {
                dispatchGroup.leave()
                continue
            }
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                defer { dispatchGroup.leave() }
                
                if let error = error {
                    print("下载图片失败: \(urlList[i]), 错误: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else { return }
                
                switch i {
                case 0: imageData1 = data
                case 1: imageData2 = data
                case 2: imageData3 = data
                default: break
                }
            }.resume()
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(imageData1, imageData2, imageData3)
        }
    }
    
    /// 加载本地POI数据
    func loadLocalUserPOI() {
        if let localData = UserPOILocalDBManager.shared.queryValidData() {
//            self.localUserPOIList = localData
            print("📚 加载本地POI数据: \(localData.count) 条")
        }
    }
    
    /// 获取单个POI详情并保存到本地
    /// - Parameter id: POI ID
    /// - Returns: 包含POI详情的Publisher
    func fetchAndSaveUserPoiDetail(id: String) -> AnyPublisher<UserPOIData, MapError> {
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
                            
                            if baseResponse.success, let networkData = baseResponse.data {
                                // 保存单个POI到本地
                                self.saveUserPoiDetailToLocal(networkData)
                                
                                promise(.success(networkData))
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
    
    /// 保存单个POI详情到本地
    /// - Parameter networkData: 网络获取的POI详情数据
    private func saveUserPoiDetailToLocal(_ poiData: UserPOIData) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            
            // 转换altitude
            let altitudeDouble = poiData.altitude.flatMap { Double($0) }
            
            var localData = UserPOILocalData(
                poiId: poiData.poiId,
                name: poiData.name,
                address: poiData.address,
                description: poiData.description,
                lon: poiData.lon,
                lat: poiData.lat,
                category: poiData.category,
                imageData1: "",
                imageData2: "",
                imageData3: "",
                isDelected: false,
                isHide: false,
                altitude: altitudeDouble,
                isSynchronousNetwork: true // 来自网络的数据，标记为已同步
            )
            
            if let imgUrlList = poiData.imgUrlList {
                for (index, imageUrl) in imgUrlList.enumerated() {
                    if index == 0 {
                        localData.imageData1 = imageUrl
                    }
                    if index == 1 {
                        localData.imageData2 = imageUrl
                    }
                    if index == 2 {
                        localData.imageData3 = imageUrl
                    }
                }
            }
            
            // 检查是否存在
            if let poiId = poiData.poiId {
                if UserPOILocalDBManager.shared.query(byPoiId: poiId) == nil {
                    // 不存在，插入
                    if UserPOILocalDBManager.shared.insertOrUpdate(poiData: localData) {
                        print("✅ 保存单个POI成功: \(poiId)")
                    }
                } else {
                    print("ℹ️ POI已存在，跳过: \(poiId)")
                }
            }
            
            // 更新UI
            self.loadLocalUserPOI()
            POISyncManager.shared.checkUnsyncedStatus()
        }
    }
    
    private func updateUserPoiDetailToLocal(_ poiData: UserPOIData, oldPoiId: String) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self, var localData = UserPOILocalDBManager.shared.query(byPoiId: oldPoiId) else { return }
            
            localData.poiId = poiData.poiId
            localData.lat = poiData.lat
            localData.lon = poiData.lon
            if let imgUrlList = poiData.imgUrlList, !imgUrlList.isEmpty {
                // 确保数组索引存在
                if imgUrlList.indices.contains(0) {
                    localData.imageData1 = imgUrlList[0]
                }
                if imgUrlList.indices.contains(1) {
                    localData.imageData2 = imgUrlList[1]
                }
                if imgUrlList.indices.contains(2) {
                    localData.imageData3 = imgUrlList[2]
                }
            } 
            UserPOILocalDBManager.shared.update(poiData: localData, byId: localData.id ?? 99999)
            // 更新UI
            self.loadLocalUserPOI()
            POISyncManager.shared.checkUnsyncedStatus()
        }
    }
    
    public func uploadLocalPOIDataToNetwork(_ poiData: UserPOILocalData, type: String) {
        
        // 收集所有存在的图片路径
        var imagePaths: [String] = []
        
        if let imageUrl1 = poiData.imageData1 {
            imagePaths.append(imageUrl1)
        }
        if let imageUrl2 = poiData.imageData2 {
            imagePaths.append(imageUrl2)
        }
        if let imageUrl3 = poiData.imageData3 {
            imagePaths.append(imageUrl3)
        }
        
        // 如果没有图片，直接上传数据
        guard !imagePaths.isEmpty else {
            uploadPOIData(poiData, imgUrlList: [])
            return
        }
        
        // 使用 DispatchGroup 管理多个上传任务
        let group = DispatchGroup()
        let uploadQueue = DispatchQueue(label: "com.yourapp.imageUpload", attributes: .concurrent)
        var uploadedUrls: [String] = []
        var uploadErrors: [Error] = []
        
        // 使用线程安全的数组操作
        let urlLock = NSLock()
        
        for imagePath in imagePaths {
            group.enter()
            
            // 在后台队列处理图片上传
            uploadQueue.async { [weak self] in
                defer { group.leave() }
                
                guard let self = self,
                      let image = ImageManager.shared.getImage(from: imagePath) else {
                    print("无法加载图片: \(imagePath)")
                    return
                }
                
                // 创建信号量用于同步上传
                let semaphore = DispatchSemaphore(value: 0)
                var uploadedUrl: String?
                var uploadError: Error?
                
                self.uploadImage(image: image, imagePatch: imagePath) { result in
                    switch result {
                    case .success(let fileurl):
                        uploadedUrl = fileurl
                    case .failure(let error):
                        uploadError = error
                        print("图片上传失败: \(error.localizedDescription)")
                    }
                    semaphore.signal()
                }
                
                _ = semaphore.wait(timeout: .now() + 30) // 30秒超时
                
                // 线程安全地添加URL
                if let url = uploadedUrl {
                    urlLock.lock()
                    uploadedUrls.append(url)
                    urlLock.unlock()
                } else if let error = uploadError {
                    urlLock.lock()
                    uploadErrors.append(error)
                    urlLock.unlock()
                }
            }
        }
        
        // 所有上传任务完成后
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            if !uploadErrors.isEmpty {
                print("有 \(uploadErrors.count) 张图片上传失败")
                // 可以根据需求决定是否继续上传POI数据
            }
            if type == "save" {
                self.savePOIData(poiData, imgUrlList: uploadedUrls)
            } else if type == "update" {
                self.uploadPOIData(poiData, imgUrlList: uploadedUrls)
            }
        }
    }

    // 抽取出上传POI数据的方法
    private func savePOIData(_ poiData: UserPOILocalData, imgUrlList: [String]) {
        let userId = UserManager.shared.userId
        
        guard let number = Int(userId) else {
            print("用户ID转换失败")
            return
        }
        
        let poiModel = UserPOIModel(
            poiId: poiData.poiId ?? "",
            name: poiData.name ?? "",
            description: poiData.description ?? "",
            lon: poiData.lon ?? 0,
            lat: poiData.lat ?? 0,
            category: poiData.category ?? 1,
            imgUrlList: imgUrlList,
            state: 0,
            userId: number,
            address: poiData.address ?? "",
            altitude: "\(poiData.altitude ?? 0)"
        )
        
        _ = saveUserPoi(poiModel)
    }
    
    // 抽取出上传POI数据的方法
    private func uploadPOIData(_ poiData: UserPOILocalData, imgUrlList: [String]) {
        let userId = UserManager.shared.userId
        
        guard let number = Int(userId) else {
            print("用户ID转换失败")
            return
        }
        
        let poiModel = UserPOIModel(
            poiId: poiData.poiId ?? "",
            name: poiData.name ?? "",
            description: poiData.description ?? "",
            lon: poiData.lon ?? 0,
            lat: poiData.lat ?? 0,
            category: poiData.category ?? 1,
            imgUrlList: imgUrlList,
            state: 0,
            userId: number,
            address: poiData.address ?? "",
            altitude: "\(poiData.altitude ?? 0)"
        )
        
        _ = updateUserPoi(poiModel)
    }
    
    private func uploadImage(
        image: UIImage,
        imagePatch: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        uploadService.uploadImage(
            image,
            fileName: "my_photo.jpg",
            compressionQuality: 0.8,
            progressHandler: { _ in
                // 可以在这里添加进度回调
            },
            completion: { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        if response.isSuccess, let fileUrl = response.data?.fileUrl {
                            print("上传成功！文件URL: \(fileUrl)")
                            ImageManager.shared.deleteImage(at: imagePatch)
                            completion(.success(fileUrl))
                        } else {
                            let error = NSError(
                                domain: "UploadError",
                                code: -1,
                                userInfo: [NSLocalizedDescriptionKey: response.msg ?? "上传失败"]
                            )
                            print("上传失败: \(response.msg ?? "未知错误")")
                            completion(.failure(error))
                        }
                    case .failure(let error):
                        print("上传错误: \(error.localizedDescription)")
                        completion(.failure(error))
                    }
                }
            }
        )
    }
}
