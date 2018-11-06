//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class TokenRLM: Object {
    @objc dynamic var contractAddress = String()
    @objc dynamic var ticker = String()             //short name
    @objc dynamic var name = String()
    @objc dynamic var decimals  = NSNumber(value: -1)// mark missing decimals
    @objc dynamic var currencyID = NSNumber(value: 0)
    @objc dynamic var netType   = NSNumber(value: 0)
    
    override class func primaryKey() -> String? {
        return "contractAddress"
    }
    
    var blockchainType: BlockchainType {
        get {
            return BlockchainType(blockchain: Blockchain(currencyID.uint32Value), net_type: netType.intValue)
        }
    }
    
    //func makeIcon by address for example or ticker
    
    public class func initArrayWithArray(tokensArray: NSArray, blockchainType: BlockchainType) -> [TokenRLM] {
        var tokens = [TokenRLM]()
        
        for tokenInfo in tokensArray {
            let token = TokenRLM.initWithInfo(tokensInfo: tokenInfo as! NSDictionary, blockchainType: blockchainType)
            tokens.append(token)
        }
        
        return tokens
    }
    
    public class func initWithInfo(tokensInfo: NSDictionary, blockchainType: BlockchainType) -> TokenRLM {
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
        
        if let decimals = tokensInfo["Decimals"] {
            erc20token.decimals = decimals as! NSNumber
        }
        
        erc20token.currencyID = NSNumber(value: blockchainType.blockchain.rawValue)
        erc20token.netType = NSNumber(value: blockchainType.net_type)
        
        return erc20token
    }
}
