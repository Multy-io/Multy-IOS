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
