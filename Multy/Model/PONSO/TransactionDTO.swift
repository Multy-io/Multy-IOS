//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class TransactionDTO: NSObject {
    var sendAddress : String?
    var sendAmount: BigInt?
    var requestedAmount: BigInt?
    
    var blockchain: Blockchain?
    
    var choosenWallet: UserWalletRLM? {
        didSet {
            if choosenWallet != nil {
                blockchain = choosenWallet!.blockchain
            }
        }
    }
    
    var feeRate: BigInt?
    var feeAmount: BigInt? {
        get {
            return feeRate
        }
    }
    
    var rawValue: String?
    
    var donationAmount: BigInt?
    
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
            sendAmount = BigInt(sendAmountString)
            blockchain = Blockchain.blockchainFromString(blockchainName)
        default:
            return
        }
    }
}

class BTCTransactionDTO: TransactionDTO {
    var newChangeAddress: String?
}

class ETHTransactionDTO: TransactionDTO {
    var gasLimit: BigInt?
    
    override var feeAmount: BigInt? {
        if gasLimit != nil && feeRate != nil {
            return gasLimit! * feeRate!
        }
        
        return nil
    }
}
