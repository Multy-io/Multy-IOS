//
//  DappOperation.swift
//  Multy
//
//  Created by Alex Pro on 10/8/18.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import Foundation
import BigInt

enum DappOperationType : String, Decodable {
    case
    signTransaction =       "signTransaction",
    signMessage =           "signMessage",
    signPersonalMessage =   "signPersonalMessage",
    signTypedMessage =      "signTypedMessage"
}

struct OperationObject {
    var chainID:    NSNumber
    var hexData:    String
    var fromAddress: String
    var toAddress:  String
    var gasPrice:   UInt64
    var gasLimit:   UInt64
    var nonce:      Int
    var value:      String
    
    
    init(with object: Dictionary<String, Any>) {
        if let chainID =  object["chainId"] as? NSNumber {
            self.chainID = chainID
        } else {
            chainID = 4
        }
        
        if let hexData =  object["data"] as? String {
            self.hexData = String(hexData.dropFirst(2))
        } else {
            self.hexData = ""
        }
        
        if let fromAddress =  object["from"] as? String {
            self.fromAddress = fromAddress
        } else {
            self.fromAddress = ""
        }
        
        if let toAddress =  object["to"] as? String {
            self.toAddress = toAddress
        } else {
            self.toAddress = ""
        }
        
        if let gas =  object["gas"] as? String {
            self.gasLimit = UInt64(gas.dropFirst(2), radix: 16)!
        } else {
            self.gasLimit = UInt64("\(2_000_000)")!
        }
        
        if let gasPriceString =  object["gasPrice"] as? String {
            self.gasPrice = UInt64(gasPriceString.dropFirst(2), radix: 16)!
        } else {
            self.gasPrice = 0
        }
        
        if let nonceString =  object["nonce"] as? String {
            self.nonce = Int(nonceString, radix: 16)!
        } else {
            self.nonce = 0
        }
        
        //amount
        if let valueString =     object["value"] as? String {
            if let value = BigUInt(valueString.dropFirst(2), radix: 16) {
                self.value = value.description
            } else {
                self.value = "0"
            }
        } else {
            self.value = "0"
        }
    }
}
