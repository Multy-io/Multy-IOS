//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class MultisigWallet: Object {
    
    @objc dynamic var chainType = NSNumber(value: 1)
    
    @objc dynamic var factoryAddress = String()
    
    @objc dynamic var txOfCreation = String()
    
    @objc dynamic var inviteCode = String()
    
    @objc dynamic var signaturesRequiredCount = Int()
    
    @objc dynamic var ownersCount = Int()
        
    @objc dynamic var deployStatus = NSNumber(value: 0)
    
    @objc dynamic var isDeleted = NSNumber(booleanLiteral: false)
    
    @objc dynamic var linkedWalletID = String()
    
    var owners = List<MultisigOwnerRLM>()
}
