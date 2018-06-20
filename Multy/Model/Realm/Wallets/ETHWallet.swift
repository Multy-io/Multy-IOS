//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class ETHWallet: Object {
    @objc dynamic var nonce = NSNumber(value: 0)
    @objc dynamic var balance = "0"
    @objc dynamic var pendingWeiAmountString = "0"
    
    var allBalance: BigInt {
        get {
            let balanceBigInt = BigInt(balance)
            
            return pendingWeiAmountString == "0" ? balanceBigInt : pendingBalance
        }
    }
    
    var availableBalance: BigInt {
        get {
            let balanceBigInt = BigInt(balance)
            
            return pendingWeiAmountString == "0" ? balanceBigInt : (balanceBigInt < pendingBalance ? balanceBigInt : BigInt.zero())
        }
    }
    
    var pendingBalance: BigInt {
        get {
            return BigInt(pendingWeiAmountString)
        }
    }
    
    var isThereAvailableBalance: Bool {
        get {
            return availableBalance > Int64(0)
        }
    }
    
    var pendingETHAmountString: String {
        get {
            return pendingWeiAmountString.appendDelimeter(at: 18)
        }
    }
}
