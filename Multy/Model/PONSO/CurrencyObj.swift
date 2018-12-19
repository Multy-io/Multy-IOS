//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

class CurrencyObj: NSObject {
    
    var currencyImgName = ""
    var currencyShortName = ""
    var currencyFullName = ""
    var currencyBlockchain = BlockchainType.create(currencyID: 0, netType: 0)
    var tokenAddress = ""
    var tokenImageURLString = ""
    
    var isToken: Bool {
        return tokenAddress.isEmpty == false
    }
    
    class func createCurrencyObj(blockchain: BlockchainType) -> CurrencyObj {
        let currencyObj = CurrencyObj()
        
        currencyObj.currencyBlockchain = blockchain
        currencyObj.currencyImgName = blockchain.iconString
        currencyObj.currencyShortName = blockchain.shortName
        currencyObj.currencyFullName = blockchain.fullName
        
        return currencyObj
    }
    
    class func createCurrencyObj(erc20Token: TokenRLM) -> CurrencyObj {
        let currencyObj = CurrencyObj()
        
        currencyObj.currencyBlockchain = BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: Int(ETHEREUM_CHAIN_ID_MAINNET.rawValue))
        currencyObj.tokenImageURLString = erc20Token.tokenImageURLString
        currencyObj.currencyShortName = erc20Token.ticker
        currencyObj.currencyFullName = erc20Token.name
        currencyObj.tokenAddress = erc20Token.contractAddress
        
        return currencyObj
    }
}
