//
//  DMTokenExtension.swift
//  Multy
//
//  Created by Alex Pro on 11/6/18.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import Foundation
import Web3

extension DataManager {
    func supportedTokens(tikersArray: Array<String>) -> [TokenRLM] {
        let savedTokens = Array(DataManager.shared.realmManager.erc20Tokens.values)
        
        return savedTokens.filter { tikersArray.contains($0.ticker.lowercased()) }
    }
    
    func updateTokensInfo(_ tokensarray: [TokenRLM]) {
        if tokensarray.count == 0 {
            return
        }
        
        let tokenCount = tokensarray.count
        var newTokenInfo = [TokenRLM]()
        
//        let blockchainType = tokensarray.first!.blockchainType
        
//        let rpcURL = (blockchainType.net_type == ETHEREUM_CHAIN_ID_MAINNET.rawValue ? "https://mainnet.infura.io/v3/78ae782ed28e48c0b3f74ca69c4f7ca8" : (UInt32(blockchainType.net_type) == ETHEREUM_CHAIN_ID_RINKEBY.rawValue ? "https://rinkeby.infura.io/v3/78ae782ed28e48c0b3f74ca69c4f7ca8" : "" ))
//        let web3 = Web3(rpcURL: rpcURL)
        let web3Mainnet = Web3(rpcURL: "https://mainnet.infura.io/v3/78ae782ed28e48c0b3f74ca69c4f7ca8")
        let web3Rinkeby = Web3(rpcURL: "https://rinkeby.infura.io/v3/78ae782ed28e48c0b3f74ca69c4f7ca8")
        
        tokensarray.forEach { [unowned self] in
            let newToken = TokenRLM()
            newToken.contractAddress = $0.contractAddress
            newToken.currencyID     = $0.currencyID
            newToken.netType        = $0.netType
            newToken.ticker         = $0.ticker
            newToken.name           = $0.name
            newToken.decimals       = $0.decimals
            
            let contractAddress = try! EthereumAddress(hex: $0.contractAddress.lowercased(), eip55: false)
            let contract = newToken.netType.int32Value == ETHEREUM_CHAIN_ID_MAINNET.rawValue ?
                web3Mainnet.eth.Contract(type: GenericERC20Contract.self, address: contractAddress) :
                web3Rinkeby.eth.Contract(type: GenericERC20Contract.self, address: contractAddress)
            let name = contract.name()
            let decimals = contract.decimals()
            let symbol = contract.symbol()
                        
            name.call { [unowned self] (dict, error) in
                if dict != nil, dict!.keys.count > 0 {
                    newToken.name = dict!.values.first! as! String
                }
                
                //EOS name fix
                if  newToken.contractAddress.lowercased() == "0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0" {
                    newToken.name = "EOS"
                }
                
                decimals.call { [unowned self] (dict, error) in
                    if dict != nil, dict!.keys.count > 0 {
                        newToken.decimals = dict!.values.first! as! NSNumber
                    } else {
                        newToken.decimals = 0
                    }
                    
                    symbol.call { [unowned self] (dict, error) in
                        if dict != nil, dict!.keys.count > 0 {
                            newToken.ticker = dict!.values.first! as! String
                        }
                        
                        //lock access to newTokenInfo
//                        objc_sync_enter(newTokenInfo)
                        
                        newTokenInfo.append(newToken)
                        print("newTokenInfo: \(newTokenInfo.count)")
                        
                        if newTokenInfo.count == tokenCount {
                            DispatchQueue.main.async { [unowned self] in
                                self.realmManager.updateErc20Tokens(tokens: newTokenInfo)
                            }
                        }
//                        objc_sync_exit(newTokenInfo)
                    }
                }
            }
        }
    }
}
