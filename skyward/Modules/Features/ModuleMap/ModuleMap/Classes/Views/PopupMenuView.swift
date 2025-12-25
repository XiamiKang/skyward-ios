//
//  PopupMenuItem.swift
//  yifan_test
//
//  Created by TXTS on 2025/12/2.
//


import UIKit

enum MenuType {
    case poi
    case track
}
// MARK: - 弹出菜单选项
struct PopupMenuItem {
    let title: String
    let iconName: String
    let action: () -> Void
    
    init(title: String, iconName: String, action: @escaping () -> Void) {
        self.title = title
        self.iconName = iconName
        self.action = action
    }
}

// MARK: - 弹出菜单视图
class PopupMenuView: UIView {
    
    // MARK: - Properties
    private let items: [PopupMenuItem]
    private let triangleHeight: CGFloat = 8
    let type: MenuType
    
    typealias DismissHandler = () -> Void
    private struct AssociatedKeys {
        static var onDismiss = "onDismiss"
    }
    
    var onDismiss: DismissHandler? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.onDismiss) as? DismissHandler
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.onDismiss, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - UI Components
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    private let triangleView: TriangleView = {
        let view = TriangleView()
        view.fillColor = UIColor.black.withAlphaComponent(0.8)
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.showsVerticalScrollIndicator = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    // MARK: - Initialization
    init(items: [PopupMenuItem], type: MenuType = .poi) {
        self.items = items
        self.type = type
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(triangleView)
        addSubview(containerView)
        containerView.addSubview(tableView)
    }
    
    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        triangleView.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // 三角形在右上角
        NSLayoutConstraint.activate([
            triangleView.topAnchor.constraint(equalTo: topAnchor),
            triangleView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            triangleView.widthAnchor.constraint(equalToConstant: 16),
            triangleView.heightAnchor.constraint(equalToConstant: triangleHeight)
        ])
        
        // 容器在三角形下方
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: triangleView.bottomAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // TableView填满容器
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])
        
        // 设置自身高度
        let rowHeight: CGFloat = 50
        let totalHeight = CGFloat(items.count) * rowHeight + triangleHeight + 16 // 16是内边距
        self.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
    }
    
    // MARK: - Show/Hide
    func show(from view: UIView, at point: CGPoint) {
        // 添加到指定视图
        view.addSubview(self)
        
        // 设置frame（右上角对齐）
        let width: CGFloat = 180
        let height = CGFloat(items.count) * 50 + triangleHeight + 16
        
        self.frame = CGRect(
            x: point.x - width + 16, // 向右偏移16点，让三角形指向正确位置
            y: point.y,
            width: width,
            height: height
        )
        
        // 添加动画
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn) {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        } completion: { _ in
            self.removeFromSuperview()
        }
    }
    
    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 点击空白处隐藏
        if let touch = touches.first {
            let location = touch.location(in: self)
            if !containerView.frame.contains(location) && !triangleView.frame.contains(location) {
                hide()
            }
        }
    }
}

// MARK: - 三角形视图
class TriangleView: UIView {
    
    private let triangleLayer = CAShapeLayer()
    
    var fillColor: UIColor = .black {
        didSet {
            triangleLayer.fillColor = fillColor.cgColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        
        // 配置三角形图层
        triangleLayer.fillColor = fillColor.cgColor
        triangleLayer.strokeColor = nil
        triangleLayer.lineWidth = 0
        layer.addSublayer(triangleLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateTrianglePath()
    }
    
    private func updateTrianglePath() {
        let triangleWidth: CGFloat = bounds.width
        let triangleHeight: CGFloat = bounds.height
        
        let path = UIBezierPath()
        
        if triangleWidth > 0 && triangleHeight > 0 {
            // 绘制朝上的三角形
            // 点1：左下角
            let point1 = CGPoint(x: 0, y: triangleHeight)
            // 点2：顶部中点（尖尖）
            let point2 = CGPoint(x: triangleWidth / 2, y: 0)
            // 点3：右下角
            let point3 = CGPoint(x: triangleWidth, y: triangleHeight)
            
            path.move(to: point1)
            path.addLine(to: point2)
            path.addLine(to: point3)
            path.close()
            
//            print("朝上三角形路径:")
//            print("  bounds: \(bounds)")
//            print("  左下角: \(point1)")
//            print("  顶部中点: \(point2)")
//            print("  右下角: \(point3)")
        }
        
        triangleLayer.path = path.cgPath
    }
}

// MARK: - 菜单单元格
class PopupMenuCell: UITableViewCell {

    let type: MenuType
    
    // MARK: - UI Components
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .white
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        return view
    }()
    
    // MARK: - Initialization
    init(style: UITableViewCell.CellStyle, reuseIdentifier: String?, type: MenuType) {
        self.type = type
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(separatorView)
    }
    
    private func setupConstraints() {
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        
        if type == .track {
            NSLayoutConstraint.activate([
                // 标题
                titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                
                // 图标
                iconImageView.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 12),
                iconImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 24),
                iconImageView.heightAnchor.constraint(equalToConstant: 24),
                
                // 分隔线
                separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        } else {
            NSLayoutConstraint.activate([
                // 图标
                iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 24),
                iconImageView.heightAnchor.constraint(equalToConstant: 24),
                
                // 标题
                titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
                titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                
                // 分隔线
                separatorView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                separatorView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                separatorView.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        }
    }
    
    // MARK: - Configuration
    func configure(with item: PopupMenuItem, isLast: Bool = false) {
        titleLabel.text = item.title
        iconImageView.image = MapModule.image(named: item.iconName) ?? UIImage(systemName: "plus")
        separatorView.isHidden = isLast
    }
}

// MARK: - UITableView DataSource & Delegate
extension PopupMenuView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = PopupMenuCell(style: .default, reuseIdentifier: "PopupMenuCell", type: type)
        let item = items[indexPath.row]
        let isLast = indexPath.row == items.count - 1
        cell.configure(with: item, isLast: isLast)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        item.action()
        hide()
    }
}

