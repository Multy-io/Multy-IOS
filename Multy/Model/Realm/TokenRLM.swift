//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class TokenRLM: Object {
    @objc dynamic var contractAddress = String()
    @objc dynamic var ticker = String()             //short name
    @objc dynamic var name = String()
    
    override class func primaryKey() -> String? {
        return "contractAddress"
    }
    
    //func makeIcon by address for example or ticker
    
    public class func initArrayWithArray(tokensArray: NSArray) -> [TokenRLM] {
        var tokens = [TokenRLM]()
        
        for tokenInfo in tokensArray {
            let token = TokenRLM.initWithInfo(tokensInfo: tokenInfo as! NSDictionary)
            tokens.append(token)
        }
        
        return tokens
    }
    
    public class func initWithInfo(tokensInfo: NSDictionary) -> TokenRLM {
        let erc20token = TokenRLM()
        
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
