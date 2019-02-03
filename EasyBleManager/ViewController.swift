//
//  ViewController.swift
//  EasyBleManager
//
//  Created by Howard on 2019/2/1.
//  Copyright © 2019 Howard. All rights reserved.
//

import UIKit

let DeviceVersion = "XXXX"
let DeviceMode = "XXXX"

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func connectBle(_ sender: UIButton) {
        //获取连接上的设备
        let connectedDevice = EasyBleManager.shareInstance.connectedDevice()
        if connectedDevice == nil {
            //蓝牙变化时回调
            EasyBleManager.shareInstance.bleStateChangeBlock = {(state) in
                print("蓝牙状态:\(state)")
            }
            //配置可扫描到的设备名称
            EasyBleManager.shareInstance.acceptableDeviceNames = ["UFO"]
            //扫描超时加调
            EasyBleManager.shareInstance.bleScanTimeoutBlock = {
                print("扫描超时")
            }
            //连接超时加调
            EasyBleManager.shareInstance.bleConnectTimeoutBlock = {
                print("连接超时")
            }
            //扫描成功回调
            EasyBleManager.shareInstance.bleScanSuccessBlock = {(device) in
                EasyBleManager.shareInstance.connectDevice(device)
                EasyBleManager.shareInstance.stopScan()
            }
            //设备连接成功回调，但设备这时还不能直接去读写
            EasyBleManager.shareInstance.bleConnectSuccessBlock = {
                (_) in
            }
            //此时设备已经准备就绪，随时可以读写操作
            EasyBleManager.shareInstance.deviceReadyBlock = {(_) in
            }
            //检查蓝牙是否可用
            if EasyBleManager.shareInstance.isBleEnable {
                //开始扫描设备
                EasyBleManager.shareInstance.scanForDevices()
            } else {
                print("蓝牙不可用")
            }
            
        } else {
            print("设备已连接上了")
        }
    }
    //读取设备信息
    @IBAction func readData(_ sender: Any) {
        let bleDevice = EasyBleManager.shareInstance.connectedDevice()
        bleDevice?.readDeviceInfo(DeviceVersion, complete: { (value) in
            var versionString = ""
            if value != nil {
                versionString = String.init(data: value!, encoding: String.Encoding.utf8) ?? ""
            }
            print("设备版本号:\(versionString)")
        })
    }
    //向设备写入数据
    @IBAction func writeData(_ sender: Any) {
        let bleDevice = EasyBleManager.shareInstance.connectedDevice()
        let bytes: [UInt8] = [0x10]
        bleDevice?.writeDevice(DeviceMode, bytes: bytes) { (success) in
            if success {
                print("写入成功")
            } else {
                print("写入失败")
            }
        }
    }
    
}

