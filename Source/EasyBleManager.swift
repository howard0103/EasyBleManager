//
//  EasyBleManager.swift
//  EasyBleManager
//
//  Created by Howard on 2019/2/1.
//  Copyright © 2019 Howard. All rights reserved.
//


import UIKit
import CoreBluetooth

//MARK:-定义
//蓝牙状态
public enum BleState {
    case PowerOff
    case PowerOn
}

public typealias ReadDeviceInfoBlock = (_ object: Data?) -> Void //获取设备信息block
public typealias WriteDeviceBlock = (_ success: Bool) -> Void //写入数据block

//MARK:-蓝牙控制类
open class EasyBleManager: NSObject {
    public static let shareInstance = EasyBleManager()
    //MARK:公共属性和方法
    //系统蓝牙状态改变
    public var bleStateChangeBlock:((_ state: BleState) -> Void)?
    //扫描到设备后回调
    public var bleScanSuccessBlock:((_ device: EasyBleDevice) -> Void)?
    //扫描超时回调
    public var bleScanTimeoutBlock:(() -> Void)?
    //连接设备成功后回调
    public var bleConnectSuccessBlock:((_ device: EasyBleDevice) -> Void)?
    //连接超时回调
    public var bleConnectTimeoutBlock:(() -> Void)?
    //设备所有特性已经获取完毕，可以随时读写操作
    public var deviceReadyBlock:((_ device: EasyBleDevice) -> Void)?
    //扫描超时时间
    public var scanTimeoutInterval: TimeInterval!
    //连接超时时间
    public var connectTimeoutInterval: TimeInterval!
    //蓝牙是否可用
    public private(set) var isBleEnable: Bool = false
    
    //MARK:私有属性
    private var group: DispatchGroup?
    private var bleEnableBlock:((_ enable: Bool) -> Void)?
    private var state: BleState = .PowerOff
    private var scanTimeoutTimer: Timer?
    private var connectTimeroutTimer: Timer?
    private var currentManager: CBCentralManager?
    private var currentPeripheral: CBPeripheral?
    private var willConnectDevices: NSMutableArray!
    private var connectedDevices: NSMutableArray!
    
    override init() {
        super.init()
        self.scanTimeoutInterval = defaultScanTimeoutInterval
        self.connectTimeoutInterval = defaultConnectTimeoutInterval
        self.willConnectDevices = NSMutableArray()
        self.connectedDevices = NSMutableArray()
        group = DispatchGroup()
        group!.enter()
        let queue = DispatchQueue(label: "com.howard.queue")
        self.currentManager = CBCentralManager(delegate: self, queue: queue, options: nil)
        group!.wait()
    }
}

//MARK:-公共方法
extension EasyBleManager {
    //扫描设备
    public func scanForDevices() {
        if self.currentManager != nil && self.isBleEnable {
            self.invalidateTimer(self.scanTimeoutTimer)
            self.scanTimeoutTimer = Timer.scheduledTimer(timeInterval: self.scanTimeoutInterval, target: self, selector: #selector(timeoutScan), userInfo: nil, repeats: false)
            self.currentManager!.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    //连接设备
    public func connectDevice(_ device: EasyBleDevice) {
        guard let peripheral = device.peripheral else { return }
        if self.currentManager != nil && self.isBleEnable {
            self.addDeviceToConnectQueue(device)
            self.currentManager!.connect(peripheral, options: nil)
        }
    }
    //获取已连接上的设备
    public func connectedDevice() -> EasyBleDevice? {
        return connectedDevices?.firstObject as? EasyBleDevice
    }
    //停止扫描
    public func stopScan() {
        if self.currentManager != nil {
            self.currentManager!.stopScan()
        }
        self.invalidateTimer(self.scanTimeoutTimer)
    }
}

//MARK:-私有方法
extension EasyBleManager {
    //更新蓝牙状态
    private func updateManagerState(_ central: CBCentralManager?) {
        guard let central = central else { return }
        switch central.state {
        case .poweredOn:
            self.state = .PowerOn
        default:
            self.state = .PowerOff
        }
        self.isBleEnable = (self.state == .PowerOn)
    }
    //取消定时器
    private func invalidateTimer(_ timer: Timer?) {
        var myTimer = timer
        myTimer?.invalidate()
        myTimer = nil
    }
    //扫描超时回调
    @objc private func timeoutScan() {
        self.currentManager?.stopScan()
        self.invalidateTimer(self.scanTimeoutTimer)
        if bleScanTimeoutBlock != nil {
            self.bleScanTimeoutBlock!()
        }
    }
    //连接超时回调
    @objc private func timeoutConnect(timer: Timer) {
        let device =  timer.userInfo as? EasyBleDevice
        guard let bleDevice = device else { return }
        guard let peripheral = bleDevice.peripheral else { return }
        self.currentManager?.cancelPeripheralConnection(peripheral)
        self.removeDeviceFromConnectQueue(bleDevice)
        if bleConnectTimeoutBlock != nil {
            self.bleConnectTimeoutBlock!()
        }
    }
    //添加设备到连接队列
    private func addDeviceToConnectQueue(_ device: EasyBleDevice) {
        device.delegate = self
        self.invalidateTimer(self.connectTimeroutTimer)
        DispatchQueue.main.async(execute: {
            self.connectTimeroutTimer = Timer.scheduledTimer(timeInterval: self.connectTimeoutInterval, target: self, selector: #selector(self.timeoutConnect(timer:)), userInfo: device, repeats: false)
        })
        self.willConnectDevices.add(device)
    }
    //从连接队列里移除设备
    private func removeDeviceFromConnectQueue(_ device: EasyBleDevice?) {
        guard let device = device else { return }
        self.invalidateTimer(self.connectTimeroutTimer)
        self.willConnectDevices.remove(device)
    }
    //根据peripheral获取Device
    private func deviceWithPeripheral(_ peripheral: CBPeripheral) -> EasyBleDevice? {
        for device in self.willConnectDevices {
            let bleDevice = device as! EasyBleDevice
            if bleDevice.peripheral == peripheral {
                return bleDevice
            }
        }
        return nil
    }
}

//MARK:-蓝牙协议
extension EasyBleManager: CBCentralManagerDelegate {
    //蓝牙状态变化协议
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        self.updateManagerState(central)
        if self.bleStateChangeBlock != nil {
            self.bleStateChangeBlock!(self.state)
        }
        if group != nil {
            group!.leave()
            group = nil
        }
    }
    //扫描成功协议
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        debug_log("发现设备:\(peripheral.name ?? "<null>")")
        if let acceptableDeviceNames = EasyBleConfig.acceptableDeviceNames {
            if !(acceptableDeviceNames.contains(peripheral.name ?? "")) {
                return
            }
        }
        let bleDevice = EasyBleDevice(peripheral)
        if self.bleScanSuccessBlock != nil {
            self.bleScanSuccessBlock!(bleDevice)
        }
    }
    //连接成功协议
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debug_log("连接成功")
        self.currentPeripheral = peripheral
        let bleDevice = self.deviceWithPeripheral(peripheral)
        guard let device = bleDevice else { return }
        self.removeDeviceFromConnectQueue(device)
        self.connectedDevices.add(device)
        peripheral.delegate = device
        var services: [CBUUID]?
        if let serviceUUIDs =  EasyBleConfig.acceptableDeviceServiceUUIDs {
            if !(serviceUUIDs.isEmpty) {
                services = [CBUUID]()
                for uuid in serviceUUIDs {
                    let cbUUID = CBUUID(string: uuid)
                    services?.append(cbUUID)
                }
            }
        }
        peripheral.discoverServices(services)
        if self.bleConnectSuccessBlock != nil{
            self.bleConnectSuccessBlock!(device)
        }
    }
    //连接失败协议
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        debug_log("连接失败")
        let bleDevice = self.deviceWithPeripheral(peripheral)
        guard let device = bleDevice else { return }
        self.removeDeviceFromConnectQueue(device)
        self.connectedDevices.remove(device)
    }
}

//MARK:-EasyBleDeviceDelegate
extension EasyBleManager: EasyBleDeviceDelegate {
    func deviceDidBecomeReady(_ device: EasyBleDevice) {
        if deviceReadyBlock != nil {
            deviceReadyBlock!(device)
        }
    }
    
    
}
