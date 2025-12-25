//
//  PersonalViewModel.swift
//  Pods
//
//  Created by TXTS on 2025/11/19.
//
//
import Foundation
import Moya
import SWNetwork
import Combine
import SWKit

// MARK: - 首页ViewModel
public class PersonalViewModel: ObservableObject {
 
    // MARK: - 依赖
    private let personalService = PersonalServer()
    
    // MARK: - 输出属性（使用 @Published 直接定义）
    @Published public var deviceListData: [MiniDeviceData]?
    @Published public var deviceFirmwareData: FirmwareData?
    @Published public var emergencyInfoData: EmergencyInfoData?
    @Published public var userInfoData: UserInfoData?
    @Published public var error: PersonalError?
    @Published public var isLoading = false
    
    // MARK: - 输入
    public struct Input {
        let deviceListRequest = PassthroughSubject<BaseModel, Never>()
        let deviceFirmwareRequest = PassthroughSubject<DeviceFirmwareModel, Never>()
        let emergencyRequest = PassthroughSubject<Void, Never>()
        let getUserInfoRequest = PassthroughSubject<Void, Never>()
    }
    
    // MARK: - 属性
    public let input = Input()
    public var cancellables = Set<AnyCancellable>()
    
    // MARK: - 初始化
    public init() {
        bind()
    }
    
    // MARK: - 绑定
    private func bind() {
        // 绑定获取设备列表
        input.deviceListRequest
            .flatMap { [weak self] model -> AnyPublisher<[MiniDeviceData], PersonalError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放")).eraseToAnyPublisher()
                }
                return self.fetchDeviceList(model: model)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.deviceListData = data
            }
            .store(in: &cancellables)
        
        // 绑定获取设备列表
        input.deviceFirmwareRequest
            .flatMap { [weak self] model -> AnyPublisher<FirmwareData, PersonalError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放")).eraseToAnyPublisher()
                }
                return self.fetchDeviceFirmware(model: model)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.deviceFirmwareData = data
            }
            .store(in: &cancellables)
        
        // 绑定获取紧急联系人
        input.emergencyRequest
            .flatMap { [weak self] model -> AnyPublisher<EmergencyInfoData, PersonalError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放")).eraseToAnyPublisher()
                }
                return self.checkEmergency()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.emergencyInfoData = data
            }
            .store(in: &cancellables)
        
        // 绑定获取用户信息
        input.getUserInfoRequest
            .flatMap { [weak self] _ -> AnyPublisher<UserInfoData, PersonalError> in
                guard let self = self else {
                    return Fail(error: .networkError("ViewModel 已释放")).eraseToAnyPublisher()
                }
                return self.checkUserInfo()
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.error = error
                }
            } receiveValue: { [weak self] data in
                self?.userInfoData = data
            }
            .store(in: &cancellables)
    }
    
    
}

extension PersonalViewModel {
    // 获取设备列表
    public func fetchDeviceList(model: BaseModel) -> AnyPublisher<[MiniDeviceData], PersonalError> {
        isLoading = true
        
        return Future<[MiniDeviceData], PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.getDeviceList(model) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<[MiniDeviceData]>.self, from: response.data)
                            
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
    
    // 解绑设备
    public func unBingMiniDevice(model: UnBindModel) -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.unBingMiniDevice(model) { result in
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
    
    // 退出登录
    public func logout() -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.userLogout() { [weak self] result in
                DispatchQueue.main.async {
                    
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<Bool>.self, from: response.data)
                            
                            if baseResponse.success {
                                if let data = baseResponse.data {
                                    promise(.success(data))
                                } else {
                                    promise(.success(false))
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
        .handleEvents(receiveCompletion: { [weak self] _ in
            // 额外的安全保证：无论成功失败都重置 loading
            self?.isLoading = false
        })
        .eraseToAnyPublisher()
    }
    
    // 获取设备固件信息
    public func fetchDeviceFirmware(model: DeviceFirmwareModel) -> AnyPublisher<FirmwareData, PersonalError> {
        isLoading = true
        
        return Future<FirmwareData, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.getDeviceFirmware(model) { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<FirmwareData>.self, from: response.data)
                            
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
    
    // MARK: - 获取紧急联系人
    private func checkEmergency() -> AnyPublisher<EmergencyInfoData, PersonalError> {
        isLoading = true
        
        return Future<EmergencyInfoData, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.getEmergencyContact { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<EmergencyInfoData>.self, from: response.data)
                            
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
    
    // MARK: - 更新紧急联系人
    public func updateEmergencyContact(model: EmergencyContactModel) -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        guard NetworkMonitor.shared.isConnected else {
            if let _ = BluetoothManager.shared.connectedPeripheral {
                SWAlertView.showAlert(title: nil, message: "当前无网络连接，通过Mini设备绑定紧急联系人？") {
                    if let data = MessageGenerator.generateBindEmergencyContact(userId: UserManager.shared.userId,
                                                                                phone: model.phone,
                                                                                name: model.name) {
                        BluetoothManager.shared.sendAppCustomData(data)
                    }
                }
                
            } else {
                UIWindow.topWindow?.sw_showWarningToast("请先连接Mini设备")
            }
            
            // 当无网络连接时，返回成功结果
            DispatchQueue.main.async { [weak self] in
                self?.isLoading = false
            }
            return Just(true)
                .setFailureType(to: PersonalError.self)
                .eraseToAnyPublisher()
        }
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.addEmergencyContact(model) { result in
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
    
    // MARK: - 获取用户信息
    private func checkUserInfo() -> AnyPublisher<UserInfoData, PersonalError> {
        isLoading = true
        
        return Future<UserInfoData, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.getUserInfo { result in
                DispatchQueue.main.async {
                    self.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<ResponseUserInfoData>.self, from: response.data)
                            
                            if baseResponse.success, let data = baseResponse.data?.userInfo {
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
    
    // MARK: - 更新用户头像
    public func updateAvatar(imageUrl: String) -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.updateUserAvatar(avatarUrl: imageUrl) { result in
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
    // MARK: - 更新用户性别
    public func updateGender(gender: Int) -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.updateUserSex(sex: gender) { result in
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
    
    // 注销账号
    public func cancelAccount() -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.cancellationUser() { [weak self] result in
                DispatchQueue.main.async {
                    
                    self?.isLoading = false
                    
                    switch result {
                    case .success(let response):
                        do {
                            let baseResponse = try JSONDecoder().decode(BaseResponse<Bool>.self, from: response.data)
                            
                            if baseResponse.success {
                                if let data = baseResponse.data {
                                    promise(.success(data))
                                } else {
                                    promise(.success(false))
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
        .handleEvents(receiveCompletion: { [weak self] _ in
            // 额外的安全保证：无论成功失败都重置 loading
            self?.isLoading = false
        })
        .eraseToAnyPublisher()
    }
    
    // MARK: - 更新用户昵称
    public func updateNickName(nickName: String) -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.updateUserNickname(nickname: nickName) { result in
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
    
    // MARK: - 更新用户简介
    public func updateIntroduction(introduction: String) -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.updateUserSign(personalitySign: introduction) { result in
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
    
    // MARK: - 更新用户城市
    public func updateCity(city: String, cityCode: String) -> AnyPublisher<Bool, PersonalError> {
        isLoading = true
        
        return Future<Bool, PersonalError> { [weak self] promise in
            guard let self = self else { return }
            
            self.personalService.updateUserCity(city: city, cityCode: cityCode) { result in
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
    
}
