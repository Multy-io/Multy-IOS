//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

class ETHTransactionDTO: NSObject {
    var gasLimit: BigInt?
    var gasPrice: BigInt?
    
    var feeAmount: BigInt? {
        if gasLimit != nil && gasPrice != nil {
            return gasLimit! * gasPrice!
        }
        
        return nil
    }
}
