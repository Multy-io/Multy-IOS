//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class MultisigWallet: Object {
    
    @objc dynamic var factoryAddress = String()
    
    @objc dynamic var TxOfCreation = String()
    
    @objc dynamic var inviteCode = String()
    
    @objc dynamic var signaturesRequired = Int()
    
    @objc dynamic var ownersCount = Int()
        
    @objc dynamic var deployStatus = NSNumber(value: 0)
    
    @objc dynamic var status = NSNumber(value: 0)
    
    @objc dynamic var linkedWalletID = NSNumber(value: 0)
    
    var owners = List<MultisigOwnerRLM>()
}
