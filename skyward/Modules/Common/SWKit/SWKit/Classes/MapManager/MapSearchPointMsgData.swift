//
//  MapSearchPointMsgData.swift
//  Pods
//
//  Created by TXTS on 2026/4/3.
//

import Foundation

public struct MapSearchPointMsgData: Codable {
    public let regionCode: String?
    public let name: String?
    public let address: String?
    public let longitude: Double?
    public let latitude: Double?
    public let altitude: String?
}
