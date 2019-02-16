//
//  EasyBleHelper.swift
//  EasyBleManager
//
//  Created by Howard on 2019/2/13.
//  Copyright © 2019 Howard. All rights reserved.
//
    

import UIKit

class EasyBleHelper: NSObject {
    //data转hexstring
    static func hexString(data: Data) -> String {
        return data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> String in
            let buffer = UnsafeBufferPointer(start: bytes, count: data.count)
            return buffer.map{String(format: "%02hhx", $0)}.reduce("", {$0 + $1})
            
        }
    }
    //hextstring转string
    static func stringFromHexString(hex: String) -> String? {
        var hex = hex
        var data = Data()
        while hex.count > 0 {
            let c: String = String(hex[hex.startIndex..<hex.index(hex.startIndex, offsetBy: 2)])
            hex = String(hex[hex.index(hex.startIndex, offsetBy: 2)..<hex.endIndex])
            var ch: uint = 0
            Scanner(string: c).scanHexInt32(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        return String(data: data, encoding: .utf8)
    }
    //hexstring转nsnumber
    static func numberFromHexString(hex: String) -> NSNumber? {
        var number: uint = 0
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        scanner.scanHexInt32(&number)
        return NSNumber(value: number)
    }
    //hexData转mac地址
    static func macAddressFromHexData(hexData: Data) -> String? {
        var hexStr = EasyBleHelper.hexString(data: hexData)
        for index in [2, 5, 8, 11, 14] {
            hexStr.insert(":", at: hexStr.index(hexStr.startIndex, offsetBy: index))
        }
        return hexStr
    }
}
