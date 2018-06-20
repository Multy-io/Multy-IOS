//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import Branch

protocol BranchProtocol {
    
}

extension BranchProtocol {
    func createDeepLink(completion: @escaping (_ url: String?) -> ()) {
        let branch = Branch.getInstance()
        let branchInfo = branchDict(BLOCKCHAIN_BITCOIN, "1PteA8L32kBjwqNAtBao4h6ZKJjJuDVuPG", "0.0")
        
        branch?.getShortURL(withParams: branchInfo, andChannel: "Create option \"Multy\"", andFeature: "sharing", andCallback: { (url, err) in
            completion(url)
        })
    }
    
    func branchDict(_ blockchain: Blockchain, _ address: String, _ amount: String) -> [String : Any] {
        let dict: NSDictionary = ["$og_title" : "Multy",
                                  "address"   : blockchain.qrBlockchainString + ":" + address,
                                  "amount"    : amount]
        
        return dict as! [String : Any]
    }
}
