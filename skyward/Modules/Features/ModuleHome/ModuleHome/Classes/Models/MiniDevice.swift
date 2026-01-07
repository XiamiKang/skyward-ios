//
//  MiniDevice.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/25.
//

import ModulePersonal
import SWKit

struct MiniDevice {
    let info: MiniDeviceData
    var status: StatusInfo?
    var satelliteNum: Int?
    var connected: Bool = false
    let selected: Bool = false
}
