//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class Erc20TokensRLM: Object {
    @objc dynamic var contractAddress = String()
    @objc dynamic var ticker = String()             //short name
    @objc dynamic var name = String()
    
    override class func primaryKey() -> String? {
        return "contractAddress"
    }
    
    //func makeIcon by address for example or ticker
    
    public class func initArrayWithArray(tokensArray: NSArray) -> [Erc20TokensRLM] {
        var tokens = [Erc20TokensRLM]()
        
        for tokenInfo in tokensArray {
            let token = Erc20TokensRLM.initWithInfo(tokensInfo: tokenInfo as! NSDictionary)
            tokens.append(token)
        }
        
        return tokens
    }
    
    public class func initWithInfo(tokensInfo: NSDictionary) -> Erc20TokensRLM {
        let erc20token = Erc20TokensRLM()
        
        if let contractAddress = tokensInfo["ContractAddress"] {
            erc20token.contractAddress = contractAddress as! String
        }
        
        if let ticker = tokensInfo["Ticker"] {
            erc20token.ticker = ticker as! String
        }
        
        if let name = tokensInfo["Name"] {
            erc20token.name = name as! String
        }
        
        return erc20token
    }
}
