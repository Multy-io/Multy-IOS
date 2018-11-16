//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class TransactionDTO: NSObject {
    var sendAddress : String?
    var sendAmountString: String?
    var requestedAmount: Double?
    
    var blockchain: Blockchain?
    
    var choosenWallet: UserWalletRLM? {
        didSet {
            if choosenWallet != nil {
                blockchainType = BlockchainType.create(wallet: choosenWallet!)
                blockchain = choosenWallet!.blockchain
                
                assetsBlockchainType = assetsWallet.blockchainType
                assetsBlockchain = assetsBlockchainType.blockchain
                
                switch blockchain! {
                case BLOCKCHAIN_BITCOIN:
                    BTCDTO = BTCTransactionDTO()
                case BLOCKCHAIN_ETHEREUM:
                    ETHDTO = ETHTransactionDTO()
                case BLOCKCHAIN_ERC20:
                    ETHDTO = ETHTransactionDTO()
                default:
                    break
                }
            }
        }
    }
    
    var isTokenTransfer: Bool {
        return blockchain == BLOCKCHAIN_ERC20
    }
    
    var blockchainObject: Any? {
        return choosenWallet!.blockchain == BLOCKCHAIN_ERC20 ? choosenWallet!.token : blockchain
    }
    
    var assetsWallet: UserWalletRLM {
        return choosenWallet!.blockchain == BLOCKCHAIN_ERC20 ? tokenHolderWallet! : choosenWallet!
    }
    
    var tokenHolderWallet: UserWalletRLM?
    
    var blockchainType: BlockchainType?
    
    var assetsBlockchainType = BlockchainType(blockchain: BLOCKCHAIN_BITCOIN, net_type: 0)
    var assetsBlockchain = BLOCKCHAIN_BITCOIN
    
    var sumInCrypto: BigInt {
        return choosenWallet!.convertCryptoAmountStringToMinimalUnits(amountString: sendAmountString!)
    }
    
    var feeRate: BigInt? {
        didSet {
            guard feeRate != nil else {
                return
            }
            
            if blockchain != nil && (blockchain! == BLOCKCHAIN_ETHEREUM || blockchain! == BLOCKCHAIN_ERC20) {
                ETHDTO?.gasPrice = feeRate!
            } else {
                BTCDTO?.feePerByte = feeRate!
            }
        }
    }
    
    var feeRateName: String?
    
    var feeEstimation: BigInt?
    
    var rawValue: String?
    
    var donationAmount: BigInt?
    
    var BTCDTO: BTCTransactionDTO?
    var ETHDTO: ETHTransactionDTO?
    
    func update(from qrString: String) {
        let array = qrString.components(separatedBy: CharacterSet(charactersIn: ":?="))
        switch array.count {
        case 1:
            sendAddress = array[0]
        case 2:                              // chain name + address
            let blockchainName = array[0]
            sendAddress = array[1]
            blockchain = Blockchain.blockchainFromString(blockchainName)
        case 4:                                // chain name + address + amount
            let blockchainName = array[0]
            sendAddress = array[1]
            let sendAmountString = array[3]
            self.sendAmountString = sendAmountString
            blockchain = Blockchain.blockchainFromString(blockchainName)
        default:
            return
        }
    }
    
    override var description: String {
        return "sendAddress: \(sendAddress!)\nsendAmountString: \(sendAmountString!)\nfeeEstimation: \(feeEstimation!)"
    }
}
