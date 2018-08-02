//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class EOSWallet: Object {
    @objc dynamic var balance = "0"
    @objc dynamic var pendingUnitsAmountString = "0"
    
    var pendingBalance: BigInt {
        get {
            return BigInt(pendingUnitsAmountString)
        }
    }
    
    var eosBalance: BigInt {
        get {
            return BigInt(balance)
        }
    }
}
