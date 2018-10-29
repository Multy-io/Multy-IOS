//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import Branch
//import MultyCoreLibrary

protocol BranchProtocol {
    
}

extension BranchProtocol {
    func createDeepLink(_ address: String?, completion: @escaping (_ url: String?) -> ()) {
        let branch = Branch.getInstance()
        let branchInfo = branchDict(BLOCKCHAIN_BITCOIN, address, nil)
        
        branch?.getShortURL(withParams: branchInfo, andChannel: "Create option \"Multy\"", andFeature: "sharing", andCallback: { (url, err) in
            completion(url)
        })
    }
    
    func branchDict(_ blockchain: Blockchain, _ address: String?, _ amount: String?) -> [String : Any] {
        var dict: Dictionary<String, Any> = ["$og_title" : "Multy"]
        
        if let addressString = address {
            dict["address"] = blockchain.qrBlockchainString + ":" + addressString
        }
        
        if let amountString = amount {
            dict["amount"] = amountString
        }
        
        return dict
    }
}
