//
//  UserPOIDetailViewController.swift
//  ModuleMap
//
//  Created by TXTS on 2025/12/17.
//

import UIKit

class UserPOIDetailViewController: UIViewController {
    
    var poiData: UserPOIData?
    private var weatherData: WeatherData?
    private var hoursData: [EveryHoursWeatherData]?
    private var daysData: [EveryDayWeatherData]?
    private var warningData: [WeatherWarningData]?
    private var precipData: [EveryHoursPrecipData]?
    private let viewModel = WeatherViewModel()
    
    private var titleSegmentedView: TitleSegmentedView!
    private var userPointMsgView = UIView()
    private let tableView = UITableView()
    
    // 底部工具栏
    private let bottomToolView = UserBottomToolView()
    
    // 用于计算高度的容器
    private let contentContainerView = UIView()
    
    // 头部视图
    private let headerView = UIView()
    private let locationLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    init(poiData: UserPOIData) {
        self.poiData = poiData
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UserPOIDetailViewController: UISheetPresentationControllerDelegate {
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        // 当sheet高度变化时，确保底部工具栏在最上层
        view.bringSubviewToFront(bottomToolView)
    }
}
