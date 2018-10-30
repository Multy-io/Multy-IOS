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
    
    private var cryptoName: String {
        get {
            let result = transactionDTO.blockchain?.shortName
            return result != nil ? result! : ""
        }
    }
    
    private var fiatName: String {
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
    
    private var sumInCrypto = BigInt.zero()
    private var sumInFiat = BigInt.zero()
    private var totalSum: BigInt {
        get {
            let result = isInputInCrypto ? (sumInCrypto + feeInCrypto) : (sumInFiat + feeInFiat)
            return result
        }
    }
    
    private var feeInCrypto = BigInt.zero()
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
        if transactionDTO.sendAmountString != nil && blockchain != nil {
            sumInCrypto = transactionDTO.sendAmountString!.convertCryptoAmountStringToMinimalUnits(in: blockchain!)
            sumInFiat = sumInCrypto * exchangeCourse
        }
        
        if transactionDTO.transaction?.transactionRLM?.sumInCryptoBigInt != nil {
            let limit = transactionDTO.choosenWallet!.isMultiSig ? "400000" : "40000"
            feeAmount = BigInt(limit) * transactionDTO.transaction!.transactionRLM!.sumInCryptoBigInt
            feeAmountInFiat = feeAmount * exchangeCourse
        }
    }
}
