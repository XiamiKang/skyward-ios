//
//  MapViewController+Route.swift
//  ModuleMap
//
//  Created by zhaobo on 2026/2/28.
//

import Foundation
import TangramMap
import SWKit

extension MapViewController {
    
    private func routeList() -> [Route] {
        return routeDataManager.getRoutes(type: .route) + routeDataManager.getRoutes(type: .track)
    }
    
    // MARK: - Markers
    
    func registeRouteMarkerLayers() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        _ = markerLayerManager.createLayer(id: "route_line", name: "我的路线", isVisible: true)
        _ = markerLayerManager.createLayer(id: "route_node", name: "我的路线节点", isVisible: true)
        _ = markerLayerManager.createLayer(id: "track_start", name: "轨迹起点", isVisible: true)
        _ = markerLayerManager.createLayer(id: "track_end", name: "轨迹终点", isVisible: true)
    }
    
    func removeRouteMarkerLayers() {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        
        markerLayerManager.removeAllMarkers(in: "route_line")
        markerLayerManager.removeAllMarkers(in: "route_node")
        markerLayerManager.removeAllMarkers(in: "track_start")
        markerLayerManager.removeAllMarkers(in: "track_end")
    }
    
    func loadRoutesMarkers() {
        
        removeRouteMarkerLayers()
        
        routeList().forEach { route in
            addRouteMarker(route)
        }
    }
    
    func addRouteMarker(_ route: Route) {
        guard let markerLayerManager = mapManager.markerLayerManager, route.isVisible == true else {
            return
        }
        
        let routeId = route.id
        let coordinates = routeDataManager.readCoordinatesFromGPXFile(from: routeId)
        if coordinates.count > 1 {
            markerLayerManager.addLineMarker(to: "route_line", id: "\(routeId)", coordinates: coordinates, title:"", subTitle: "")
            if route.type == RouteType.track.rawValue {
                markerLayerManager.addPointMarker(to: "track_start", id: "start_\(routeId)", coordinate: coordinates.first!)
                markerLayerManager.addPointMarker(to: "track_end", id: "end_\(routeId)", coordinate: coordinates.last!)
            } else {
                coordinates.forEach { coordinate in
                    markerLayerManager.addPointMarker(to: "route_node", id: "\(routeId)_\(coordinate.longitude)", coordinate: coordinate)
                }
            }
        }
    }
    
    func removeRouteMarker(_ route: Route) {
        guard let markerLayerManager = mapManager.markerLayerManager else {
            return
        }
        let routeId = route.id
        markerLayerManager.removeMarker("\(routeId)", from: "route_line")
        
        if route.type == RouteType.track.rawValue {
            markerLayerManager.removeMarker("start_\(routeId)", from: "track_start")
            markerLayerManager.removeMarker("end_\(routeId)", from: "track_end")
        } else {
            let coordinates = routeDataManager.readCoordinatesFromGPXFile(from: routeId)
            coordinates.forEach { coordinate in
                markerLayerManager.removeMarker("\(routeId)_\(coordinate.longitude)", from: "route_node")
            }
        }
    }
    
    func cameraPositionMarkers(_ routeId: String) {
        let coordinates = routeDataManager.readCoordinatesFromGPXFile(from: routeId)
        guard let mapView = mapManager.mapView, let (sw, ne) = MapMarkerTool.getSWAndNE(coordinates) else {
            return
        }
        let bounds = TGCoordinateBounds(sw: sw, ne: ne)
        let cameraPosition = mapView.cameraThatFitsBounds(bounds, withPadding: UIEdgeInsets(top: 180, left: 60, bottom: 280, right: 60))
        mapView.setCameraPosition(cameraPosition, withDuration: 0.3, easeType: .linear)
    }
    
    // MARK: - private
    
    func presentRouteDetail(data: MarkerData) {
        let route = routeList().first { $0.id == data.id }
        guard let route = route else { return }
        
        // 防止重复弹出
        guard isDetailViewShowing == false else { return }
        isDetailViewShowing = true

        let customView = LookRoutePopupView(route: route)

        // 使用约束布局，让高度根据子视图自适应
        view.addSubview(customView)
        customView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        // 强制布局以获取实际高度
        customView.layoutIfNeeded()

        // 设置初始位置在屏幕底部之外
        customView.transform = CGAffineTransform(translationX: 0, y: customView.bounds.height)

        // 从底部弹出动画
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            customView.transform = .identity
        }

        customView.closeHandler = { [weak self] in
            self?.dismissRouteDetail(customView)
        }

        customView.deleteHandler = { [weak self] in
            let name = route.type == RouteType.track.rawValue ? RouteType.track.name() : RouteType.route.name()
            SWAlertView.showAlert(title: nil, message: "确定删除该\(name)吗？") {
                self?.deleteRoute(route: route) { [weak self] success in
                    if success {
                        self?.removeRouteMarker(route)
                        self?.dismissRouteDetail(customView)
                    }
                }
            }
        }

        customView.editHandler = { [weak self] in
            self?.presentEditRoute(route: route) { [weak self] updatedRoute in
                self?.editRoute(route: updatedRoute) { success in
                    if success {
                        customView.configure(route: updatedRoute)
                    }
                }
            }
        }

        customView.uploadHandler = { [weak self] in
            self?.saveRoute(route: route) { [weak self] success in
                if success {
                    self?.dismissRouteDetail(customView)
                }
            }
        }

        customView.showHandler = { [weak self] show in
            self?.visibleRoute(route: route, show: show)
        }
    }

    private func dismissRouteDetail(_ detailView: LookRoutePopupView) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseIn) {
            detailView.transform = CGAffineTransform(translationX: 0, y: detailView.bounds.height)
        } completion: { _ in
            detailView.removeFromSuperview()
            self.isDetailViewShowing = false
        }
    }
    
    private func presentEditRoute(route: Route, completion: @escaping (Route) -> Void) {
        var popupContainer: SWPopupView?
        let customView = AddRoutePopupView(route: route)
        customView.closeHandler = {
            popupContainer?.dismiss()
        }
        customView.confirmHandler = { name, desc in
            var updatedRoute = route
            updatedRoute.routeName = name
            updatedRoute.description = desc
            popupContainer?.dismiss()
            completion(updatedRoute)
        }
        popupContainer = SWPopupView.showFromBottom(contentView: customView)
    }
    
    // MARK: - 增删改查
    
    private func deleteRoute(route: Route, completion: @escaping (Bool) -> Void) {
        let routeId = route.id
        if route.uploaded == true {
            view.sw_showLoading()
            routeDataManager.deleteRouteFromServer(routeId: routeId) { [weak self] success in
                self?.view.sw_hideLoading()
                completion(success)
            }
        } else {
            routeDataManager.deleteRouteFromLocal(routeId)
        }
    }
    
    private func editRoute(route: Route, completion: @escaping (Bool) -> Void) {
        if route.uploaded == true {
            view.sw_showLoading()
            routeDataManager.updateRouteToServer(route) { [weak self] success in
                self?.view.sw_hideLoading()
                completion(success)
            }
        } else {
            completion(routeDataManager.updateLocalRoute(route: route))
        }
    }
    
    private func saveRoute(route: Route, completion: @escaping (Bool) -> Void) {
        view.sw_showLoading()
        assembleRoute(route: route) { [weak self] image, updatedRoute in
            self?.routeDataManager.saveRouteToServer(updatedRoute, coverImage: image) { success in
                self?.view.sw_hideLoading()
                completion(success)
            }
        }
    }
    
    private func visibleRoute(route: Route, show: Bool) {
        var newRoute = route
        newRoute.isVisible = show
        self.routeDataManager.updateLocalRoute(route: newRoute)

        if show {
            addRouteMarker(route)
        } else {
            removeRouteMarker(route)
        }
    }
    
    // MARK: - 保存上传
    
    private func assembleRoute(route: Route, completion: @escaping (UIImage?, Route) -> Void) {
        let group = DispatchGroup()

        var newRoute = route
        group.enter()
        RouteDataManager.assembleRoute(route) { updatedRoute in
            newRoute = updatedRoute
            group.leave()
        }
        
        var screenshot: UIImage?
        if RouteDataManager.getRouteCoverFromLocal(routeId: route.id) == nil {
            let coordinates = routeDataManager.readCoordinatesFromGPXFile(from: route.id)
            group.enter()
            captureScreenshot(coordinates: coordinates) { image in
                screenshot = image
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(screenshot, newRoute)
        }
    }
}
