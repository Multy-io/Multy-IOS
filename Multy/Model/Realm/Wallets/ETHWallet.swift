//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class ETHWallet: Object {
    @objc dynamic var nonce = NSNumber(value: 0)
    @objc dynamic var balance = "0"
    @objc dynamic var pendingWeiAmountString = "0"
    
    var erc20Tokens : List<WalletTokenRLM>?
    
    var pendingBalance: BigInt {
        get {
            return BigInt(pendingWeiAmountString)
        }
    }
    
    var ethBalance: BigInt {
        get {
            return BigInt(balance)
        }
    }
    
    var pendingETHAmountString: String {
        get {
            return pendingWeiAmountString.appendDelimeter(at: 18)
        }
    }
}
