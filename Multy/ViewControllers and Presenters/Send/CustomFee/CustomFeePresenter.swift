//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CustomFeePresenter: NSObject {

    var customFeeVC: CustomFeeViewController?
    
    var blockchainType: BlockchainType?
    
    let weiToGweiMultiplier = 1_000_000_000
    
    func rateForText(_ text: String) -> Int {
        var rate = Int(text)!
        switch blockchainType?.blockchain {
        case BLOCKCHAIN_BITCOIN:
            break
        case BLOCKCHAIN_ETHEREUM:
            rate = rate * weiToGweiMultiplier
        default:
            break
        }
        
        return rate
    }
    
}
