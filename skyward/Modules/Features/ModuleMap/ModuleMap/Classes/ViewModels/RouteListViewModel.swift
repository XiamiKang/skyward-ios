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
    private var total: Int = 0 {
        didSet {
            if type == .track {
                naviTitle = "历史轨迹(\(total))"
                remoteTitle = "云端(\(total - localRouteList.count))"
                localTitle = "本地(\(localRouteList.count))"
            } else {
                naviTitle = "绘制路线(\(total))"
            }
        }
    }
    
    var isLocal: Bool = false {
        didSet {
            if isLocal {
                routeList = localRouteList
            } else {
                if let remoteRouteList = remoteRouteList {
                    routeList = remoteRouteList
                } else {
                    isLoading = true
                    refresh {
                        self.isLoading = false
                    }
                }
            }
        }
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
        } else {
            naviTitle = "绘制路线"
        }
        
        // 会主动去加载数据
        isLocal = false
    }
    
    func syncRouteList() {
        if isLocal {
            localRouteList = routeList
        } else {
            remoteRouteList = routeList
        }
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
            self?.routeList = rsp?.list ?? []
            self?.total = (rsp?.total ?? 0) + (self?.localRouteList.count ?? 0)
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

    // 是否有下一页数据
    var hasNextPage: Bool {
        return routeList.count < total
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
    
    // MARK: - 列表数据编辑管理
    
    func deleteRoutes(_ routes: [Route], completion: (() -> Void)?) {
        // 取出routes中所有id
        let ids = routes.map { $0.id }
        dataManager.deleteRoutesFromServer(routeIds: ids) { [weak self] success in
            if success {
                // 删除成功后，从routeList中删除这些route
                var tempRouteList = self?.routeList ?? []
                tempRouteList.removeAll { route in
                    ids.contains(route.id)
                }
                
                self?.routeList = tempRouteList
            }
            completion?()
        }
    }
    
    // 删除已选择的route
    func deleteSelectedRoutes(completion: (() -> Void)?) {
        let routes = routeList.filter { $0.selected == true }
        deleteRoutes(routes, completion: completion)
    }
    
    // 上传已选择的route（需要等待层控制，不能上传中再做其他操作）
    func uploadSelectedRoutes(completion: (() -> Void)?) {
        // 已选择的route默认uploaded为false, 否则不合法
        let routes = routeList.filter { $0.selected == true }
        // 上传目前没有批量上传，只有遍历去传
        // 定义一个容器来存储上传结果的回调，等所有上传完成后再统一刷新tableview， 比如["id" : success]
        var uploadResults: [String: Bool] = [:]
        routes.forEach { route in
            dataManager.saveRouteToService(route) { [weak self] success in
                uploadResults[route.id] = success
                // 判断是否所有上传都完成了，如果是，则调用completion
                if uploadResults.count == routes.count {
                    // 从routeList中移除上传成功的route
                    var tempRouteList = self?.routeList ?? []
                    tempRouteList.removeAll { route in
                        uploadResults[route.id] == true && route.selected == true
                    }
                    self?.routeList = tempRouteList
                    
                    completion?()
                }
            }
        }
    }
    
    // MARK: - 处理详情页的操作结果
    
    func deleteRouteSuccess(_ route: Route) {
        var tempRouteList = routeList
        if let index = tempRouteList.firstIndex(where: { $0.id == route.id }) {
            tempRouteList.remove(at: index)
            routeList = tempRouteList
        }
    }
    
    func editRouteSuccess(_ route: Route) {
        var tempRouteList = routeList
        if let index = tempRouteList.firstIndex(where: { $0.id == route.id }) {
            tempRouteList[index] = route
            routeList = tempRouteList
        }
    }
    
    func uploadRouteSuccess(_ route: Route) {
        var tempRouteList = routeList
        if let index = tempRouteList.firstIndex(where: { $0.id == route.id }) {
            tempRouteList[index].uploaded = true
            routeList = tempRouteList
        }
    }
}
