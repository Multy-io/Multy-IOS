//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

class CustomFeePresenter: NSObject {

    var customFeeVC: CustomFeeViewController?
    
    var blockchainType: BlockchainType?
    
    let weiToGweiMultiplier = BigInt("\(1_000_000_000)")
    
    func rateForText(_ text: String) -> BigInt {
        var rate = BigInt(text)
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
    
    
    func textForRate(_ rate: BigInt) -> String {
        var result = "0"
        switch blockchainType?.blockchain {
        case BLOCKCHAIN_BITCOIN:
            result = rate.stringValue
            break
        case BLOCKCHAIN_ETHEREUM:
            result = (rate / weiToGweiMultiplier).stringValue
        default:
            break
        }
        
        return result
    }
}
