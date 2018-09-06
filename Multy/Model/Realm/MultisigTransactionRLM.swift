//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class MultisigTransactionRLM: Object {
    @objc dynamic var confirmed = NSNumber(booleanLiteral: false)
    @objc dynamic var isInternal = NSNumber(booleanLiteral: false)
    @objc dynamic var input = String()
    @objc dynamic var contractAddress = String()
    @objc dynamic var methodInvoked = String()
    @objc dynamic var invocationStatus = NSNumber(booleanLiteral: false)
    var owners = List<MultisigTransactionOwnerRLM>()
    
    public class func initWithInfo(multisigTxDict: NSDictionary) -> MultisigTransactionRLM {
        let result = MultisigTransactionRLM()
        
        if let confirmed = multisigTxDict["confirmed"] as? Bool {
            result.confirmed = NSNumber(booleanLiteral: confirmed)
        }
        
        if let isInternal = multisigTxDict["isinternal"] as? Bool {
            result.isInternal = NSNumber(booleanLiteral: isInternal)
        }
        
        if let input = multisigTxDict["input"] as? String {
            result.input = input
        }
        
        //Multisig part
        if let contractAddress = multisigTxDict["contract"] as? String {
            result.contractAddress = contractAddress
        }
        
        if let methodInvoked = multisigTxDict["methodinvoked"] as? String {
            result.methodInvoked = methodInvoked
        }
        
        if let invocationStatus = multisigTxDict["invocationstatus"] as? Bool {
            result.invocationStatus = NSNumber(booleanLiteral: invocationStatus)
        }
        
        if let owners = multisigTxDict["owners"] as? [NSDictionary] {
            result.owners = MultisigTransactionOwnerRLM.initWithArray(txOwnersArray: owners)
        }
        
        return result
    }
    
    func isNeedOnlyYourConfirmation(walletAddress: String) -> Bool {
        for owner in owners {
            if owner.address == walletAddress && owner.confirmationTx.isEmpty && owner.confirmationStatus.intValue != MultisigOwnerTxStatus.msOwnerStatusDeclined.rawValue {
                return true
            }
        }
        return false
    }
}
