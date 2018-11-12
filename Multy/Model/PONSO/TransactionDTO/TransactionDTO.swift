//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class TransactionDTO: NSObject {
    var sendAddress : String?
    var sendAmount: Double?
    var requestedAmount: Double?
    
    var blockchain: Blockchain? {
        didSet {
            guard blockchain != nil else {
                return
            }
            
            switch blockchain! {
            case BLOCKCHAIN_BITCOIN:
                BTCDTO = BTCTransactionDTO()
            case BLOCKCHAIN_ETHEREUM:
                ETHDTO = ETHTransactionDTO()
            default:
                break
            }
        }
    }
    
    var choosenWallet: UserWalletRLM? {
        didSet {
            if choosenWallet != nil {
                blockchain = choosenWallet!.blockchain
            }
        }
    }
    
    var feeRate: BigInt? {
        didSet {
            guard feeRate != nil else {
                return
            }
            
            if blockchain != nil && blockchain! == BLOCKCHAIN_ETHEREUM {
                ETHDTO?.gasPrice = feeRate
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
            sendAmount = sendAmountString.doubleValue
            blockchain = Blockchain.blockchainFromString(blockchainName)
        default:
            return
        }
    }
}
