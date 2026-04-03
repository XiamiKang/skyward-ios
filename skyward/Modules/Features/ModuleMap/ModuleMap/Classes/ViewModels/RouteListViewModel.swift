//
//  RouteListViewModel.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/9.
//

import Foundation
import Combine
import Moya
import WCDBSwift
import SWNetwork
import SWKit

// 定义一个基础的分页协议， 含pageNum和pageSize

/*
 protocol Pageable {
     var pageNum: Int { get set }  // 可读写 - 因为需要修改页码
     var pageSize: Int { get }     // 只读 - 每页数量通常固定
 }

 extension Pageable {
     var pageSize: Int { 10 }      // 为只读属性提供默认值
 }

 struct RouteListReq: Pageable, Encodable {
     let type: Int
     var pageNum: Int = 1         // 只需要声明可修改的属性
 }

 */
protocol Pageable {
    var pageNum: Int { get set }
    var pageSize: Int { get }
}

extension Pageable {
    var pageSize: Int { 10 }
}

public struct RouteListReq: Pageable, Encodable {
    let type: Int
    var pageNum: Int = 1
}

public struct RouteListRsp: Codable {
    let total: Int?
    var list: [Route]?
}

class RouteListViewModel: ObservableObject {
    
    @Published var routeList: [Route] = []
    @Published var isLoading: Bool = false
    @Published var naviTitle: String?
    @Published var localTitle: String = "本地"
    @Published var remoteTitle: String = "云端"
    
    var isManageState: Bool = false
    
    private let dataManager = RouteDataManager()
    let type: RouteType
    private var req: RouteListReq
    private var dataLoading: Bool = false
    private var localRouteList: [Route] = []
    private var remoteRouteList: [Route]?
    private var total: Int = 0
    
    private var needRefreshRemote = false
    
    var isLocal: Bool = false {
        didSet {
            if isLocal {
                routeList = localRouteList
            } else {
                if let remoteRouteList = remoteRouteList, needRefreshRemote == false {
                    routeList = remoteRouteList
                } else {
                    needRefreshRemote = false
                    isLoading = true
                    refresh {
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    // 是否有下一页数据
    private var hasNextPage: Bool {
        return routeList.count < total
    }
    
    // MARK: - Initialization
    init(type: RouteType) {
        self.type = type
        self.req = RouteListReq(type: type.rawValue)
    }
    
    // MARK: - 页面数据源
    
    func loadPageData() {
        if type == .track {
            localRouteList = dataManager.getRoutes(type: .track, onlyUnUploaded: true)
            naviTitle = "历史轨迹"
            isLocal = false
        } else {
            localRouteList = dataManager.getRoutes(type: .route, onlyUnUploaded: true)
            naviTitle = "绘制路线"
            isLoading = true
            refresh {
                self.isLoading = false
            }
        }
    }
    
    func syncRouteList() {
        if type == .track {
            if isLocal {
                localRouteList = routeList
            } else {
                remoteRouteList = routeList
            }
        }
        updateTitle()
    }
    
    func refresh(completion: @escaping () -> Void) {
        guard dataLoading == false else {
            return
        }
        dataLoading = true
        
        req.pageNum = 1
        
        dataManager.requestRouteList(req: self.req) { [weak self] rsp in
            self?.dataLoading = false
            completion()
            self?.total = (rsp?.total ?? 0) + (self?.localRouteList.count ?? 0)
            if self?.type == .track {
                self?.routeList = rsp?.list ?? []
            } else {
                self?.routeList = (self?.localRouteList ?? []) + (rsp?.list ?? [])
            }
        }
    }
    
    func loadMore(completion: (() -> Void)? = nil) {
        guard dataLoading == false else {
            return
        }
        dataLoading = true
        
        req.pageNum += 1
    
        dataManager.requestRouteList(req: self.req) { [weak self] rsp in
            self?.dataLoading = false
            completion?()
            if let remoteRoutes = rsp?.list , remoteRoutes.count > 0 {
                self?.routeList.append(contentsOf: remoteRoutes)
            } else {
                self?.req.pageNum -= 1
            }
        }
    }
    
    // 判断是否需要加载下一页
    func loadMoreIfNeeded(completion: (() -> Void)? = nil) {
        // 1. 管理模式不分页
        guard isManageState == false else { return }
        
        // 2. 本地数据不分页
        guard isLocal == false else { return }
        
        // 3. 正在加载或没有下一页
        guard isLoading == false, hasNextPage else { return }
        
        // 执行加载
        loadMore(completion: completion)
    }

    // MARK: - 状态管理
    
    func setManageState(_ manageState: Bool) {
        self.isManageState = manageState
    }
    
    func setSelectAll(_ selected: Bool) {
        // 需要把routeList里的每个route的selected 设置为all
        routeList = routeList.map { route in
            var newRoute = route
            newRoute.selected = selected
            return newRoute
        }
    }
    
    private func updateTitle() {
        if type == .track {
            naviTitle = "历史轨迹(\(total))"
            remoteTitle = "云端(\(total - localRouteList.count))"
            localTitle = "本地(\(localRouteList.count))"
        } else {
            naviTitle = "绘制路线(\(total))"
        }
    }
    
    // MARK: - 列表数据编辑管理

    func deleteRoute(_ route: Route, completion: (() -> Void)?) {
        deleteRoutes([route], completion: completion)
    }

    func deleteRoutes(_ routes: [Route], completion: (() -> Void)?) {
        if isLocal {
            // 本地删除
            routes.forEach { route in
                if self.dataManager.deleteRouteFromLocal(route.id) {
                    self.deleteRouteSuccess(route)
                }
            }
            completion?()
            return
        }
        
        // 取出routes中所有id
        let ids = routes.map { $0.id }
        dataManager.deleteRoutesFromServer(routeIds: ids) { [weak self] success in
            if success {
                // 删除成功后，从routeList中删除这些route
                self?.total -= ids.count
                self?.routeList.removeAll { route in
                    ids.contains(route.id)
                }
            }
            completion?()
        }
    }
    
    // 删除已选择的route
    func deleteSelectedRoutes(completion: (() -> Void)?) {
        let selectedRoutes = routeList.filter { $0.selected == true }
        if selectedRoutes.count == 0 {
            completion?()
            return
        }
        deleteRoutes(selectedRoutes, completion: completion)
    }
    
    func uploadRoute(_ route: Route, completion: ((Bool) -> Void)?) {
        if let index = routeList.firstIndex(where: { $0.id == route.id }) {
            routeList[index].uploading = true
        }
        RouteDataManager.assembleRoute(route) { updatedRoute in
            self.dataManager.saveRouteToServer(updatedRoute, completion: completion)
        }
    }
    
    // 上传已选择的route（需要等待层控制，不能上传中再做其他操作）
    func uploadSelectedRoutes(completion: (() -> Void)?) {
        // 已选择的route默认uploaded为false, 否则不合法
        let selectedRoutes = routeList.filter { $0.selected == true }
        if selectedRoutes.count == 0 {
            completion?()
            return
        }
        // 上传目前没有批量上传，只有遍历去传
        // 定义一个容器来存储上传结果的回调，等所有上传完成后再统一刷新tableview， 比如["id" : success]
        var uploadResults: [String: Bool] = [:]
        selectedRoutes.forEach { route in
            self.uploadRoute(route) { [weak self] success in
                uploadResults[route.id] = success
                // 判断是否所有上传都完成了，如果是，则调用completion
                if uploadResults.count == selectedRoutes.count {
                    // 从routeList中移除上传成功的route
                    self?.routeList.removeAll { uploadResults[$0.id] == true }
                    self?.remoteRouteList?.insert(contentsOf: selectedRoutes.filter { uploadResults[$0.id] == true }, at: 0)
                    completion?()
                }
            }
        }
    }
    
    // MARK: - 处理详情页的操作结果
    
    func deleteRouteSuccess(_ route: Route) {
        // 1.从当前列表（routeList）移除该轨迹
        // 2.同步列表syncRouteList（内部有判断） 由列表刷新来触发syncRouteList
        total -= 1
        routeList.removeAll { $0.id == route.id }
    }
    
    func editRouteSuccess(_ route: Route) {
        var tempRouteList = routeList
        if let index = tempRouteList.firstIndex(where: { $0.id == route.id }) {
            tempRouteList[index] = route
            routeList = tempRouteList
        }
    }
    
    func uploadRouteSuccess(_ route: Route) {
        guard type == .track else {
            return
        }
        // 1.从当前列表（routeList）移除该轨迹
        // 2.同步列表syncRouteList（内部有判断）由列表刷新来触发syncRouteList
        // 3.把该轨迹添加到remoteRouteList
        routeList.removeAll { $0.id == route.id }
//        remoteRouteList?.insert(route, at: 0)
        needRefreshRemote = true
    }
    
    func visibleRouteSuccess(_ route: Route) {
        if let index = routeList.firstIndex(where: { $0.id == route.id }) {
            routeList[index] = route
        }
    }
    
    // MARK: - 操作合法检查
    
    func checkDisableReason() -> String? {
        let selectedRoutes = routeList.filter { $0.selected == true }
        if selectedRoutes.count == 0 {
            return type == .track ? "请先勾选历史轨迹" : "请先勾选绘制路线"
        }
        return nil
    }
    
    func prepareDeleteTips() -> String {
        return type == .track ? "确定删除选中轨迹吗？" : "确定删除选中路线吗？"
    }
    
}
