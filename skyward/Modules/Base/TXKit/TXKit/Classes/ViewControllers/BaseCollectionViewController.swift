//
//  BaseCollectionViewController.swift
//  skyward
//
//  Created by 赵波 on 2025/11/12.
//

import UIKit

open class BaseCollectionViewController: BaseViewController {
    public lazy var collectionView: UICollectionView = {
        let cView = UICollectionView(frame: CGRect.zero, collectionViewLayout: collectionViewLayout)
        cView.dataSource = self
        cView.delegate = self
        
        cView.alwaysBounceVertical = true
        cView.backgroundColor = .clear
        cView.showsVerticalScrollIndicator = false
        cView.showsHorizontalScrollIndicator = false
        
        return cView
    }()
    
    open var collectionViewLayout: UICollectionViewLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 2.0
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        return flowLayout
    }()
    
    open override func setupViews() {
        super.setupViews()
        view.addSubview(self.collectionView)
    }
}

extension BaseCollectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return UICollectionViewCell()
    }
    
    
}
