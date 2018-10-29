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
    
    weak var realmManagerReference = DataManager.shared.realmManager
    
    var balabnceBigInt: BigInt {
        get {
            return BigInt(balance)
        }
    }
    
    func initERC20With(infoArray: NSArray) -> List<WalletTokenRLM> {
        let tokens = List<WalletTokenRLM>()
        
        for tokenInfo in infoArray {
            let token = WalletTokenRLM().initERC20With(dictionary: tokenInfo as! NSDictionary)
            tokens.append(token)
        }
        
        return tokens
    }
    
    func initERC20With(dictionary: NSDictionary) -> WalletTokenRLM {
        let token = WalletTokenRLM()
        
        if let address = dictionary["Address"] {
            token.address = address as! String
        }
        
        if let balance = dictionary["Balance"] {
            token.balance = balance as! String
        }
        
        if let erc20FromDB = realmManagerReference!.erc20Tokens[token.address] {
            token.ticker = erc20FromDB.ticker
            token.name = erc20FromDB.name
        } else { //not valid tokens default values
            token.ticker = "Token"
            token.name = "Token"
        }
        
        return token
    }
}



//public class func initArrayWithArray(tokensArray: NSArray) -> [Erc20TokensRLM] {
//    var tokens = [Erc20TokensRLM]()
//
//    for tokenInfo in tokensArray {
//        let token = Erc20TokensRLM.initWithInfo(tokensInfo: tokenInfo as! NSDictionary)
//        tokens.append(token)
//    }
//
//    return tokens
//}
//
//public class func initWithInfo(tokensInfo: NSDictionary) -> Erc20TokensRLM {
//    let erc20token = Erc20TokensRLM()
//
//    if let contractAddress = tokensInfo["ContractAddress"] {
//        erc20token.contractAddress = contractAddress as! String
//    }
//
//    if let ticker = tokensInfo["Ticker"] {
//        erc20token.ticker = ticker as! String
//    }
//
//    if let name = tokensInfo["Name"] {
//        erc20token.name = name as! String
//    }
//
//    return erc20token
//}
