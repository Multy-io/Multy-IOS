//
//  DappOperation.swift
//  Multy
//
//  Created by Alex Pro on 10/8/18.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import Foundation

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
    var value:      UInt64
    
    
    init(with object: Dictionary<String, Any>) {
        chainID =   object["chainId"] as! NSNumber
        let data =      object["data"] as! String
        hexData = String(data.dropFirst(2))
        
        fromAddress =      object["from"] as! String
        toAddress =        object["to"] as! String
        
        let gas =       object["gas"] as! String
        gasLimit =   UInt64(gas.dropFirst(2), radix: 16)!
        
        let gasPriceString =  object["gasPrice"] as! String
        gasPrice = UInt64(gasPriceString.dropFirst(2), radix: 16)!
        
        let nonceString =     object["nonce"] as! String
        nonce =  Int(nonceString, radix: 16)!
        
        //amount
        let valueString =     object["value"] as! String
        value = UInt64(valueString.dropFirst(2), radix: 16)!
    }
}
