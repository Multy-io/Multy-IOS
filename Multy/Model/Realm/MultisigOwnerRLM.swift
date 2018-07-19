//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class MultisigOwnerRLM: Object {
    @objc dynamic var userID = String()
    @objc dynamic var address = String()
    @objc dynamic var associated = NSNumber(booleanLiteral: false)
    @objc dynamic var creator = NSNumber(booleanLiteral: false)
    @objc dynamic var walletIndex = NSNumber(value: 0)
    @objc dynamic var addressIndex = NSNumber(value: 0)
}
