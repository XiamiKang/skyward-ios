//
//  MiniDevice.swift
//  ModuleHome
//
//  Created by zhaobo on 2025/11/25.
//

import ModulePersonal
import SWKit

struct MiniDevice {
    let info: BluetoothDeviceInfo
    var status: StatusInfo?
    var connected: Bool = false
    let selected: Bool = false
}
