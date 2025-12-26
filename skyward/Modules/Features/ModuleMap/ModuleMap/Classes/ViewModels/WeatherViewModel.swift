//
//  WeatherViewModel.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/5.
//

import Foundation
import Combine
import CoreLocation
import Moya
import SWKit

public class WeatherViewModel: ObservableObject {
    
    // MARK: - 依赖
    private let mapService = MapService()
    
    @Published public var pointWeatherData: WeatherData?
    @Published public var hoursWeatherData: [EveryHoursWeatherData]?
    @Published public var daysWeatherData: [EveryDayWeatherData]?
    @Published public var weatherWarningData: [WeatherWarningData]?
    @Published public var hoursPrecipData: [EveryHoursPrecipData]?
    @Published public var error: MapError?
    @Published public var isLoading = false
    
    // MARK: - 输入
    public struct Input {
        let pointWeatherRequest = PassthroughSubject<CLLocationCoordinate2D, Never>()
        let hoursWeatherRequest = PassthroughSubject<CLLocationCoordinate2D, Never>()
        let daysWeatherRequest = PassthroughSubject<CLLocationCoordinate2D, Never>()
        let weatherWarningRequest = PassthroughSubject<CLLocationCoordinate2D, Never>()
        let hoursPrecipRequest = PassthroughSubject<CLLocationCoordinate2D, Never>()
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
        // 绑定点位天气信息
        input.pointWeatherRequest
            .flatMap { [weak self] coordinate -> AnyPublisher<WeatherData, MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放"))
                        .eraseToAnyPublisher()
                }
                return self.fetchPointWeatherData(coordinate)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                print("📭 sink 接收到完成信号")
                switch completion {
                case .finished:
                    print("✅ 请求成功完成")
                case .failure(let error):
                    print("❌ 请求失败: \(error)")
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.pointWeatherData = data
            }
            .store(in: &cancellables)
        // 24小时天气信息
        input.hoursWeatherRequest
            .flatMap { [weak self] coordinate -> AnyPublisher<[EveryHoursWeatherData], MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放"))
                        .eraseToAnyPublisher()
                }
                return self.fetchEveryHoursWeatherData(coordinate)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                print("📭 sink 接收到完成信号")
                switch completion {
                case .finished:
                    print("✅ 请求成功完成")
                case .failure(let error):
                    print("❌ 请求失败: \(error)")
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.hoursWeatherData = data
            }
            .store(in: &cancellables)
        // 未来7天天气信息
        input.daysWeatherRequest
            .flatMap { [weak self] coordinate -> AnyPublisher<[EveryDayWeatherData], MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放"))
                        .eraseToAnyPublisher()
                }
                return self.fetchEveryDayWeatherData(coordinate)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                print("📭 sink 接收到完成信号")
                switch completion {
                case .finished:
                    print("✅ 请求成功完成")
                case .failure(let error):
                    print("❌ 请求失败: \(error)")
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.daysWeatherData = data
            }
            .store(in: &cancellables)
        // 天气预警
        input.weatherWarningRequest
            .flatMap { [weak self] coordinate -> AnyPublisher<[WeatherWarningData], MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放"))
                        .eraseToAnyPublisher()
                }
                return self.fetchWeatherWarningData(coordinate)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                print("📭 sink 接收到完成信号")
                switch completion {
                case .finished:
                    print("✅ 请求成功完成")
                case .failure(let error):
                    print("❌ 请求失败: \(error)")
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.weatherWarningData = data
            }
            .store(in: &cancellables)
        // 24小时降水量
        input.hoursPrecipRequest
            .flatMap { [weak self] coordinate -> AnyPublisher<[EveryHoursPrecipData], MapError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放"))
                        .eraseToAnyPublisher()
                }
                return self.fetchEveryHoursPrecipData(coordinate)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                print("📭 sink 接收到完成信号")
                switch completion {
                case .finished:
                    print("✅ 请求成功完成")
                case .failure(let error):
                    print("❌ 请求失败: \(error)")
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.hoursPrecipData = data
            }
            .store(in: &cancellables)
    }
    
}

// MARK: - 网络请求
extension WeatherViewModel {
    
    // MARK: - 当前天气详情
    public func fetchPointWeatherData(_ location: CLLocationCoordinate2D) -> AnyPublisher<WeatherData, MapError> {
        print("🔄 开始获取点位天气数据: \(location.latitude), \(location.longitude)")
        isLoading = true
        
        return Future<WeatherData, MapError> { [weak self] promise in
            guard let self = self else {
                print("❌ ViewModel 已释放")
                promise(.failure(.networkError("ViewModel 已释放")))
                return
            }
            
            print("📡 发送天气请求...")
            self.mapService.getPointWeatherData(location) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        print("✅ 收到天气响应")
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<WeatherData>.self, from: response.data)
                            
                            print("📊 响应状态: \(baseResponse.success), 消息: \(baseResponse.msg)")
                            
                            if baseResponse.success, let data = baseResponse.data {
                                print("🎯 天气数据解析成功: \(data)")
                                promise(.success(data))
                            } else {
                                let error = MapError.businessError(
                                    message: baseResponse.msg,
                                    code: baseResponse.code
                                )
                                print("❌ 业务错误: \(error)")
                                promise(.failure(error))
                            }
                        } catch let decodingError as DecodingError {
                            print("❌ JSON解码错误: \(decodingError)")
                            promise(.failure(.parseError("数据格式错误")))
                        } catch {
                            print("❌ 未知解析错误: \(error)")
                            promise(.failure(.parseError("数据解析失败")))
                        }
                        
                    case .failure(let error):
                        print("❌ 网络请求失败: \(error.localizedDescription)")
                        promise(.failure(.networkError(error.localizedDescription)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    
    // MARK: - 天气预警
    public func fetchWeatherWarningData(_ location: CLLocationCoordinate2D) -> AnyPublisher<[WeatherWarningData], MapError> {
        isLoading = true
        
        return Future<[WeatherWarningData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getWeatherWarningMsg(location) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[WeatherWarningData]>.self, from: response.data)
                            
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
    // MARK: - 每小时天气预报
    public func fetchEveryHoursWeatherData(_ location: CLLocationCoordinate2D) -> AnyPublisher<[EveryHoursWeatherData], MapError> {
        isLoading = true
        
        return Future<[EveryHoursWeatherData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getEveryHoursWeatherMsg(location) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[EveryHoursWeatherData]>.self, from: response.data)
                            
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
    // MARK: - 每小时降水量
    public func fetchEveryHoursPrecipData(_ location: CLLocationCoordinate2D) -> AnyPublisher<[EveryHoursPrecipData], MapError> {
        isLoading = true
        
        return Future<[EveryHoursPrecipData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getEveryHoursPrecipMsg(location) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[EveryHoursPrecipData]>.self, from: response.data)
                            
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
    // MARK: - 每日天气预报
    public func fetchEveryDayWeatherData(_ location: CLLocationCoordinate2D) -> AnyPublisher<[EveryDayWeatherData], MapError> {
        isLoading = true
        
        return Future<[EveryDayWeatherData], MapError> { [weak self] promise in
            guard let self = self else { return }
            
            self.mapService.getEveryDayWeatherMsg(location) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[EveryDayWeatherData]>.self, from: response.data)
                            
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
}
