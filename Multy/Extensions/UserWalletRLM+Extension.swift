//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

extension UserWalletRLM {
    var assetShortName: String {
        switch blockchain {
        case BLOCKCHAIN_ERC20:
            return token?.ticker ?? ""
        default:
            return blockchain.shortName
        }
    }
    
    var assetFullName: String {
        switch blockchain {
        case BLOCKCHAIN_ERC20:
            return token?.name ?? ""
        default:
            return blockchain.fullName
        }
    }
    
    var assetWalletName: String {
        switch blockchain {
        case BLOCKCHAIN_ERC20:
            return tokenHolderWallet?.name ?? ""
        default:
            return name
        }
    }
    
    var assetAddress: String {
        switch blockchain {
        case BLOCKCHAIN_ERC20:
            return tokenHolderWallet?.address ?? ""
        default:
            return address
        }
    }
    
    var assetBlockchainType: BlockchainType {
        switch blockchain {
        case BLOCKCHAIN_ERC20:
            return BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: blockchainType.net_type)
        default:
            return blockchainType
        }
    }
    
    var assetBlockchain: Blockchain {
        switch blockchain {
        case BLOCKCHAIN_ERC20:
            return BLOCKCHAIN_ETHEREUM
        default:
            return blockchain
        }
    }
    
    var assetWallet: UserWalletRLM {
        switch blockchain {
        case BLOCKCHAIN_ERC20:
            return tokenHolderWallet!
        default:
            return self
        }
    }
    
    func convertCryptoAmountStringToMinimalUnits(amountString: String) -> BigInt {
        return blockchain == BLOCKCHAIN_ERC20 ? amountString.convertCryptoAmountStringToMinimalUnits(for: blockchain) : amountString.convertCryptoAmountStringToMinimalUnits(for: token)
    }
    
    var assetPrecision: Int {
        if blockchain == BLOCKCHAIN_ERC20 {
            let token = DataManager.shared.getToken(address: address)
            return (token == nil) ? 0 : token!.precision
        } else {
            return blockchainType.blockchain.maxPrecision
        }
    }
}
