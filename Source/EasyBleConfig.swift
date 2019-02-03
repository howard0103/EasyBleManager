//
//  EasyBleConfig.swift
//  EasyBleManager
//
//  Created by Howard on 2019/2/3.
//  Copyright © 2019 Howard. All rights reserved.
//
    

import UIKit

open class EasyBleConfig: NSObject {
    //是否启用日志，默认未启用
    public static var enableLog: Bool = false
    //限定扫描到设备的名字
    public static var acceptableDeviceNames: [String]?
    //限定可发现的设备serviceUUIDs
    public static var acceptableDeviceServiceUUIDs: [String]?
    
}
