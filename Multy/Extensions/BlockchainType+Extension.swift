//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import UIKit
//import MultyCoreLibrary

typealias BlockchainTypeEquatable = BlockchainType

extension BlockchainTypeEquatable: Equatable {
    static public func == (lhs: BlockchainType, rhs: BlockchainType) -> Bool {
        return lhs.blockchain.rawValue == rhs.blockchain.rawValue && lhs.net_type == rhs.net_type
    }
}

// MARK: MUST READ
// for every new blockchain entity we have to update all calculated properties:
// iconString, shortName, fullName, qrBlockchainString
extension BlockchainType {
    var isMainnet: Bool {
        switch self.blockchain {
        case BLOCKCHAIN_BITCOIN:
            switch UInt32(self.net_type) {
            case BITCOIN_NET_TYPE_MAINNET.rawValue:
                return true
            case BITCOIN_NET_TYPE_TESTNET.rawValue:
                return false
            default:
                return false
            }
        case BLOCKCHAIN_ETHEREUM, BLOCKCHAIN_ERC20:
            switch Int32(self.net_type) {
            case ETHEREUM_CHAIN_ID_MAINNET.rawValue:
                return true
            case ETHEREUM_CHAIN_ID_RINKEBY.rawValue:
                return false
            case ETHEREUM_CHAIN_ID_MULTISIG_MAINNET.rawValue:
                return true
            case ETHEREUM_CHAIN_ID_MULTISIG_TESTNET.rawValue:
                return false
            default:
                return false
            }
        default:
            return true
        }
    }
    
    var iconString : String {
        var iconString = ""
        
        switch self.blockchain {
        case BLOCKCHAIN_BITCOIN:
            switch UInt32(self.net_type) {
            case BITCOIN_NET_TYPE_MAINNET.rawValue:
//                iconString = "btcMediumIcon"
                iconString = "btcMaediumIcon"
            case BITCOIN_NET_TYPE_TESTNET.rawValue:
//                iconString = "btcTest"
                iconString = "btcTestBg"
            default:
                iconString = ""
            }
        case BLOCKCHAIN_LITECOIN:
            iconString = "chainLtc"
        case BLOCKCHAIN_DASH:
            iconString = "chainDash"
        case BLOCKCHAIN_ETHEREUM:
            switch Int32(self.net_type) {
            case ETHEREUM_CHAIN_ID_MAINNET.rawValue:
                iconString = "ethMediumIcon"
            case ETHEREUM_CHAIN_ID_RINKEBY.rawValue:
                //iconString = "ethTest"
                iconString = "ethTestBg"
            case ETHEREUM_CHAIN_ID_MULTISIG_MAINNET.rawValue:
                iconString = "ethMSMediumIcon"
            case ETHEREUM_CHAIN_ID_MULTISIG_TESTNET.rawValue:
                iconString = "ethMSTestnet"
            default:
                iconString = ""
            }
        case BLOCKCHAIN_ETHEREUM_CLASSIC:
            iconString = "chainEtc"
        case BLOCKCHAIN_STEEM:
            iconString = "chainSteem"
        case BLOCKCHAIN_BITCOIN_CASH:
            iconString = "chainBch"
        case BLOCKCHAIN_BITCOIN_LIGHTNING:
            iconString = "chainLbtc"
        case BLOCKCHAIN_GOLOS:
            iconString = "chainGolos"
        case BLOCKCHAIN_BITSHARES:
            iconString = "chainBts"
        case BLOCKCHAIN_ERC20:
            iconString = "erc20Token"
        default:
            iconString = ""
        }
        
        return iconString
    }
    
    var shortName : String {
        return blockchain.shortName
    }
    
    var fullName : String {
        return blockchain.fullName
    }
    
    var combinedName: String {
        var result = fullName + " ∙ " + shortName
        if !isMainnet {
            result += " Testnet"
        }
        return result
    }
    
    var colorForWalletName: UIColor {
        var color = UIColor()
        switch self.blockchain {
        case BLOCKCHAIN_BITCOIN:
            color = #colorLiteral(red: 1, green: 0.6634360552, blue: 0.1786985695, alpha: 1)
        case BLOCKCHAIN_ETHEREUM:
            color = #colorLiteral(red: 0.4516705275, green: 0.5013847947, blue: 0.7878515124, alpha: 1)
        default: color = #colorLiteral(red: 1, green: 0.6634360552, blue: 0.1786985695, alpha: 1)
        }
        
        return color
    }
    
    var qrBlockchainString : String {
        return blockchain.qrBlockchainString
    }
    
    static func create(wallet: UserWalletRLM) -> BlockchainType {
        return BlockchainType.create(currencyID: wallet.chain.uint32Value, netType: wallet.chainType.uint32Value)
    }
    
    // This method relates to representation layer
    static func createAssociated(wallet: UserWalletRLM) -> BlockchainType {
        let netType = wallet.isMultiSig ? wallet.multisigWallet!.chainType.uint32Value : wallet.chainType.uint32Value
        
        return BlockchainType.create(currencyID: wallet.chain.uint32Value, netType: netType)
    }
    
    static func create(currencyID: UInt32, netType: UInt32) -> BlockchainType {
        return BlockchainType.init(blockchain: Blockchain.init(currencyID), net_type: Int(netType))
    }
}
