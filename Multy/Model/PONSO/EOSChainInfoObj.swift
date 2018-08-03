//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

class EOSChainInfo: NSObject {
    let expirationDateString: String   //chainTime
    let refBlockPrefix: String
    let blockNumber: UInt32
    
    init(expirationDateString: String, refBlockPrefix: String, blockNumber: UInt32) {
        self.expirationDateString = expirationDateString
        self.refBlockPrefix = refBlockPrefix
        self.blockNumber = blockNumber
    }
}
