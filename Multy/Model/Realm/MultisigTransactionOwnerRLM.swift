//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class MultisigTransactionOwnerRLM: Object {
    @objc dynamic var address = String()
    @objc dynamic var confirmationTx = String()
    @objc dynamic var confirmationStatus = NSNumber(value: 0) // 0 - waiting, 1 - confirmed, 2 - declined
    @objc dynamic var viewed = NSNumber(booleanLiteral: false)
    @objc dynamic var confirmationTime = NSNumber(value: 0)
    @objc dynamic var viewTime = NSNumber(value: 0)
    
    public class func initWithArray(txOwnersArray: [NSDictionary]) -> List<MultisigTransactionOwnerRLM> {
        let result = List<MultisigTransactionOwnerRLM>()
        for ownerDict in txOwnersArray {
            let owner = MultisigTransactionOwnerRLM.initWithInfo(txOwnerDict: ownerDict)
            result.append(owner)
        }
        
        return result
    }
    
    public class func initWithInfo(txOwnerDict: NSDictionary) -> MultisigTransactionOwnerRLM {
        let result = MultisigTransactionOwnerRLM()
        
        if let address = txOwnerDict["address"] as? String {
            result.address = address
        }
        
        if let confirmationTx = txOwnerDict["confirmationtx"] as? String {
            result.confirmationTx = confirmationTx
        }
        
        if let confirmation = txOwnerDict["confirmationStatus"] as? Int {
            result.confirmationStatus = NSNumber(value: confirmation)
        }
        
        if let viewed = txOwnerDict["seen"] as? Bool {
            result.viewed = NSNumber(booleanLiteral: viewed)
        }
        
        if let confirmationTime = txOwnerDict["confirmationTime"] as? Int {
            result.confirmationTime = NSNumber(value: confirmationTime)
        }
        
        if let viewTime = txOwnerDict["seenTime"] as? Int {
            result.viewTime = NSNumber(value: viewTime)
        }
        
        return result
    }
}
