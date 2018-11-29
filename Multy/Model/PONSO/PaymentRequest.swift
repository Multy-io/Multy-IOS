//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

enum Requester {
    case wallet
    case user
}

class PaymentRequest: NSObject {
    let requester : Requester
    let userID : String
    var userCode : String {
        get {
            if requester == .wallet {
                return choosenAddress!.address.convertToUserCode!
            } else {
                return userID.md5().convertToUserCode!
            }
        }
    }
    
    var supportedAddresses = List<AddressRLM>()
    var choosenAddress : AddressRLM?
    var satisfied = false
    
    init(requester: Requester, userID: String, requestData: NSDictionary) {
        self.requester = requester
        self.userID = userID
        super.init()
        
        parseData(requestData)
        
        if requester == .wallet && supportedAddresses.count > 0 {
            choosenAddress = supportedAddresses.first
        }
    }
    
    private func parseData(_ data: NSDictionary) {
        if let addresses = data["supportedAddresses"] as? NSArray {
            supportedAddresses = AddressRLM.initWithArray(addressesInfo: addresses)
        }
    }
}
