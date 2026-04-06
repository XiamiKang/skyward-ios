//
//  AroundPOIData.swift
//  Pods
//
//  Created by TXTS on 2026/4/1.
//

import Foundation

public struct AroundPOIData: Codable {
    public let id: String?              //ID
    public let name: String?            //名字
    public let distance: String?        //距离
    public let location: String?        //位置
    public let longitude: Double        //经度
    public let latitude: Double         //纬度
    public let address: String?         //地址
    
    public init(longitude: Double, latitude: Double, name: String? = nil, address: String? = nil) {
        self.id = ""
        self.name = name
        self.distance = ""
        self.location = ""
        self.longitude = longitude
        self.latitude = latitude
        self.address = address
    }
}
