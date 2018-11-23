//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class WalletTokenRLM: Object {
    @objc dynamic var address = String()
    @objc dynamic var ticker = String()
    @objc dynamic var name = String()
    @objc dynamic var balance = String()
    
    var token: TokenRLM? {
        return DataManager.shared.realmManager.erc20Tokens[address]
    }
    
    var tokenImageURLString: String {
        return "https://raw.githubusercontent.com/Multy-io/tokens/master/images/\(address).png"
    }
    
    var balanceBigInt: BigInt {
        get {
            return BigInt(balance)
        }
    }
    
    class func initERC20With(infoArray: NSArray) -> List<WalletTokenRLM> {
        let tokens = List<WalletTokenRLM>()
        
        for tokenInfo in infoArray {
            let token = WalletTokenRLM.initERC20With(dictionary: tokenInfo as! NSDictionary)
            tokens.append(token)
        }
        
        return tokens
    }
    
    class func initERC20With(dictionary: NSDictionary) -> WalletTokenRLM {
        let token = WalletTokenRLM()
        let realmManagerReference = DataManager.shared.realmManager
        
        if let address = dictionary["Address"] {
            token.address = address as! String
        }
        
        if let balance = dictionary["Balance"] {
            token.balance = balance as! String
        }
        
        if let erc20FromDB = realmManagerReference.erc20Tokens[token.address] {
            token.ticker = erc20FromDB.ticker
            token.name = erc20FromDB.name
        } else { //not valid tokens default values
            token.ticker = "Token"
            token.name = "Token"
        }
        
        return token
    }
}
