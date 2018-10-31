//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

class SendAmountPresenter: NSObject {
    var vc: SendAmountViewController?
    var transactionDTO = TransactionDTO() {
        didSet {
            disassembleTransaction()
        }
    }
    
    var cryptoName: String {
        get {
            let result = transactionDTO.blockchain?.shortName
            return result != nil ? result! : ""
        }
    }
    
    var fiatName: String {
        get {
            let result = transactionDTO.choosenWallet?.fiatName
            return result != nil ? result! : ""
        }
    }
    
    var blockchain: Blockchain? {
        get {
            let result = transactionDTO.blockchain
            return result
        }
    }
    
    var exchangeCourse = exchangeCourseDefault
    
    var isInputInCrypto = true {
        didSet {
            if oldValue != isInputInCrypto {
                vc?.updateUI()
            }
        }
    }
    
    private var sumInCrypto = BigInt.zero() {
        didSet {
            if oldValue != sumInCrypto {
                sumInFiat = BigInt("\(exchangeCourse)") * sumInCrypto
            }
        }
    }
    
    private var sumInFiat = BigInt.zero() {
        didSet {
            if oldValue != sumInFiat {
                sumInCrypto = sumInFiat / BigInt("\(exchangeCourse)")
            }
        }
    }
    
    private var totalSum: BigInt {
        get {
            let result = isInputInCrypto ? (sumInCrypto + feeInCrypto) : (sumInFiat + feeInFiat)
            return result
        }
    }
    
    private var feeInCrypto = BigInt.zero() {
        didSet {
            if oldValue != feeInCrypto {
                feeInFiat = BigInt("\(exchangeCourse)") * feeInCrypto
            }
        }
    }
    
    private var feeInFiat = BigInt.zero()
    
    var sumInCryptoString: String {
        get {
            let result = blockchain != nil ? "\(sumInCrypto.cryptoValueString(for: blockchain!)) \(cryptoName)"  : ""
            return result
        }
    }
    
    var sumInFiatString: String {
        get {
            let result = "\(sumInFiat) \(fiatName)"
            return result
        }
    }
    
    var totalSumString: String {
        get {
            let result = blockchain != nil ? "\(totalSum.cryptoValueString(for: blockchain!)) \(cryptoName)"  : ""
            return result
        }
    }
    
    func vcViewDidLoad() {
        vc?.configure()
    }
    
    func vcViewWillAppear() {
    }
    
    func vcViewDidLayoutSubviews() {
        vc?.updateUI()
    }
    
    func vcViewDidDisappear() {
        
    }
    
    private func assembleTransaction() {
        
    }
    
    private func disassembleTransaction() {
        exchangeCourse = transactionDTO.choosenWallet != nil ? transactionDTO.choosenWallet!.exchangeCourse : exchangeCourseDefault
        if transactionDTO.sendAmount?.stringValue != nil && blockchain != nil {
            sumInCrypto = transactionDTO.sendAmount!.stringValue.convertCryptoAmountStringToMinimalUnits(in: blockchain!)
        }
        
        if blockchain != nil && transactionDTO.feeAmount != nil {
            if blockchain! == BLOCKCHAIN_ETHEREUM {
                let limit = transactionDTO.choosenWallet!.isMultiSig ? "400000" : "40000"
                feeInCrypto = BigInt(limit) * transactionDTO.feeAmount!
            } else {
                feeInCrypto = transactionDTO.feeAmount!
            }
        }
    }
}
