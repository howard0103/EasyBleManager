# EasyBleManager
iOS蓝牙模块(Ble4.0)Swift版本

## 背景
swift项目中简单快速的集成iOS蓝牙模块

## 功能
-  同步获取蓝牙状态，使用更加的灵活和便捷
-  扫描设备和连接设备
-  可配置指定的设备名称、设备可被发现的Service
-  扫描和连接超时设置
-  添加设备准备就绪状态，设备连接成功后，并不能直接读写操作，要等设备准备就绪后，就随时可以读写操作
-  方便简单的读写操作
-  开启和关闭调试日志

## 要求
-  iOS 8.0+
-  Swift 4.0+

## 安装
#### CocoaPods
`Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!
pod 'EasyBleManager'
```

然后运行:
```bash
$ pod install
```

## 使用
#### 导入头文件
```swift
import EasyBleManager
```
#### 具体用法
配置需要操作的特性uuid
```swift
let DeviceVersion = "XXXX"
let DeviceMode = "XXXX"
```

检查蓝牙是否可用
```swift
if EasyBleManager.shareInstance.isBleEnable {
    print("蓝牙可用")
} else {
    print("蓝牙不可用")
}

```
获取连接上的设备
```swift
let connectedDevice = EasyBleManager.shareInstance.connectedDevice()
```

系统蓝牙状态变化时回调
```swift
EasyBleManager.shareInstance.bleStateChangeBlock = {(state) in
    print("蓝牙状态:\(state)")
}
```

开启调试日志信息
```swift
EasyBleConfig.enableLog = true //默认未启动调试日志
```

配置可扫描到的设备名称/设备可被发现的Service
 ```swift
  EasyBleConfig.acceptableDeviceNames = ["XXXX"] //默认接受所有设备
  EasyBleConfig.acceptableDeviceServiceUUIDs = ["XXXX"] //默认发现设备所有的Service
```

扫描超时回调
```swift
EasyBleManager.shareInstance.bleScanTimeoutBlock = {
    print("扫描超时")
}
```

连接超时回调
```swift
EasyBleManager.shareInstance.bleConnectTimeoutBlock = {
    print("连接超时")
}
```

扫描成功回调
```swift
EasyBleManager.shareInstance.bleScanSuccessBlock = {(_) in
    print("扫描设备成功")
}
```

设备连接成功回调，此时设备还不能直接去读写操作
```swift
EasyBleManager.shareInstance.bleConnectSuccessBlock = {(_) in
    print("设备连接成功")
}
```

设备准备就绪回调，此时可以读写操作
```swift
EasyBleManager.shareInstance.deviceReadyBlock = {(_) in
    print("设备已经准备就绪成功")
}
```

扫描设备/停止扫描
```swift
EasyBleManager.shareInstance.scanForDevices()//扫描设备
EasyBleManager.shareInstance.stopScan()//停止扫描
```

连接设备
```swift
EasyBleManager.shareInstance.connectDevice(device)
```

读取数据
```swift
device?.readDeviceInfo("设备版本号特性uuid", complete: { (value) in
    var versionString = ""
    if value != nil {
        versionString = String.init(data: value!, encoding: String.Encoding.utf8) ?? ""
    }
    print("设备版本号:\(versionString)")
})
```

写入数据
```swift
let bytes: [UInt8] = [0x10]
device?.writeDevice("设备特性uuid", bytes: bytes) { (success) in
    if success {
        print("写入成功")
    } else {
        print("写入失败")
    }
}
```

## 最后
使用过程中如果有任何问题和建议都可以随时联系我，我的邮箱 344185723@qq.com
愿大家都可以开开心心的写代码！



