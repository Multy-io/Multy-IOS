//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

enum AccountType: Int, CaseIterable {
    case
        multy =     0,
        metamask =  1
    
    init(typeID: Int) {
        if typeID >= AccountType.allCases.count || typeID < 0 {
            self = .multy
        } else {
            self = AccountType(rawValue: typeID)!
        }
    }
    
    var seedPhraseWordsCount: Int {
        switch self {
        case .multy:
            return 15
        case .metamask:
            return 12
        }
    }
}

class AccountRLM: Object {
    @objc dynamic var seedPhrase = String() {
        didSet {
            if seedPhrase != "" {
                self.backupSeedPhrase = seedPhrase
            }
        }
    }
    @objc dynamic var backupSeedPhrase = String()
    @objc dynamic var binaryDataString = String()
    
    @objc dynamic var userID = String()
    @objc dynamic var deviceID = String()
    @objc dynamic var deviceType = 1
    @objc dynamic var pushToken = String()
    
    @objc dynamic var expireDateString = String()
    @objc dynamic var token = String()
    @objc dynamic var id: NSNumber = 1
    @objc dynamic var accountTypeID: NSNumber = 0
    
    var topIndexes = List<TopIndexRLM>()
    
    @objc dynamic var walletCount: NSNumber = 0
    var wallets = List<UserWalletRLM>() {
        didSet {
            walletCount = NSNumber(value: wallets.count)
        }
    }
    
    func isSeedPhraseSaved() -> Bool {
        return seedPhrase == ""
    }

    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    var accountType: AccountType {
        return AccountType(typeID: accountTypeID.intValue)
    }
}
