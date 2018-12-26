//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

let apiQuickexKey = "e23bb19933259c45eed5"
let privateQuickexKey = "0b3048805748d1a17180"

extension DataManager {
    func marketInfo(fromBlockchain: Blockchain, toBlockchain: Blockchain, completion: @escaping(Result<NSDictionary, String>) -> ()) {
        
        let currencyPairString = self.currencyPairString(fromBlockchain: fromBlockchain, toBlockchain: toBlockchain)
        
        apiManager.marketInfo(currencyPair: currencyPairString) { completion($0) }
    }
    
    func currencyPairString(fromBlockchain: Blockchain, toBlockchain: Blockchain) -> String {
        return fromBlockchain.shortName.lowercased() + "_" + toBlockchain.shortName.lowercased()
    }
    
    func exchange(amountString: String, withdrawalAddress: String, pairString: String, returnAddress: String, tag: String = "", completion: @escaping(_ answer: Result<NSDictionary, String>) -> ()) {
        apiManager.exchange(amountString: amountString, withdrawalAddress: withdrawalAddress, pairString: pairString, returnAddress: returnAddress, apiKey: apiQuickexKey) { completion($0) }
    }
}
