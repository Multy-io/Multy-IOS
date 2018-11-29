//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

private typealias LocalizeDelegate = SendDetailsPresenter
private typealias CustomFeeRateDelegate = SendDetailsPresenter

class SendDetailsPresenter: NSObject {
    
    var vc: SendDetailsViewController?
    var transactionDTO = TransactionDTO() {
        didSet {
            availableSumInCrypto = transactionDTO.assetsWallet.availableAmount
            availableSumInFiat = transactionDTO.assetsWallet.availableAmountInFiat
            cryptoName = transactionDTO.assetsWallet.assetShortName
            fiatName = transactionDTO.choosenWallet!.fiatName
            feeRates = defaultFeeRates()
        }
    }
    
    var availableSumInCrypto    : BigInt?
    var availableSumInFiat      : BigInt?
    
    var selectedIndexOfSpeed: Int? {
        didSet {
            if oldValue != selectedIndexOfSpeed {
                vc?.updateCellsVisibility()
                updateTransaction()
            }
        }
    }
    
    // Donation
    var isDonationSwitchedOn : Bool? {
        didSet {
            if isDonationSwitchedOn != nil {
                changeDonationString(isDonationSwitchedOn! ? "\(minBTCDonationAmount)".convertCryptoAmountStringToMinimalUnits(for: transactionDTO.choosenWallet!.blockchain).cryptoValueString(for: transactionDTO.choosenWallet!.blockchain) : BigInt.zero().stringValue)
            } else {
                changeDonationString(nil)
            }
            vc?.updateDonationUI()
        }
    }
    
    var donationInCryptoString: String? {
        didSet {
            if donationInCryptoString == nil {
                donationInCrypto = nil
            } else {
                var donationStringForDouble = donationInCryptoString!
                if donationStringForDouble.last == "," {
                    donationStringForDouble.removeLast()
                }
                
                donationInCrypto = donationStringForDouble.convertCryptoAmountStringToMinimalUnits(for: transactionDTO.choosenWallet!.blockchain)
            }
        }
    }
    
    var donationInFiatString: String? {
        get {
            guard donationInCrypto != nil else {
                return nil
            }
            
            return (donationInCrypto! * transactionDTO.choosenWallet!.exchangeCourse).fiatValueString(for: transactionDTO.blockchain!)
        }
    }
    
    private var donationInCrypto: BigInt? {
        didSet {
            if oldValue != donationInCrypto {
                updateTransaction()
                vc?.updateDonationUI()
            }
        }
    }
    
    var cryptoName = ""
    var fiatName = ""
    
    var customFee = BigInt("0") {
        didSet {
            if oldValue != customFee {
                updateTransaction()
                vc?.tableView.reloadData()
            }
        }
    }
    
    var feeRates = NSDictionary() {
        didSet {
            if feeRates.count > 0 {
                customFee = BigInt("\(feeRates["VerySlow"]!)")
            }
            
            updateTransaction()
            vc?.tableView.reloadData()
        }
    }
    
    var isDonationAvailable : Bool {
        get {
            let blockchainType = transactionDTO.assetsWallet.blockchainType
            return blockchainType.blockchain == BLOCKCHAIN_BITCOIN
        }
    }
    
    
    func vcViewDidLoad() {
        vc?.setupUI()
        requestFee()
    }
    
    func vcViewWillAppear() {
        vc?.addNotificationsObservers()
    }
    
    func vcViewWillDisappear() {
        vc?.removeNotificationsObservers()
    }
    
    func requestFee() {
        DataManager.shared.getFeeRate(currencyID: transactionDTO.assetsWallet.chain.uint32Value,
                                      networkID: transactionDTO.assetsWallet.chainType.uint32Value,
                                      ethAddress: transactionDTO.assetsWallet.blockchain == BLOCKCHAIN_ETHEREUM ? transactionDTO.sendAddress : nil,
                                      completion: { [weak self] (dict, error) in
                                        guard self != nil else {
                                            return
                                        }
                                        
                                        self!.vc?.loader.hide()
                                        
                                        if dict != nil, let fees = dict!["speeds"] as? NSDictionary {
                                            self!.feeRates = fees
                                        } else {
                                            print("Did failed getting feeRate")
                                        }
        })
    }
    
    func defaultFeeRates() -> NSDictionary {
        return transactionDTO.assetsWallet.blockchain == BLOCKCHAIN_BITCOIN ? DefaultFeeRates.btc.feeValue : DefaultFeeRates.eth.feeValue
    }
    
    func feeRateForIndex(_ index: Int) -> (name: String, value: BigInt) {
        switch index {
        case 0:
            return (localize(string: Constants.veryFastString), BigInt("\(feeRates["VeryFast"]!)"))
        case 1:
            return (localize(string: Constants.fastString), BigInt("\(feeRates["Fast"]!)"))
        case 2:
            return (localize(string: Constants.mediumString), BigInt("\(feeRates["Medium"]!)"))
        case 3:
            return (localize(string: Constants.slowString), BigInt("\(feeRates["Slow"]!)"))
        case 4:
            return (localize(string: Constants.verySlowString), BigInt("\(feeRates["VerySlow"]!)"))
        case 5:
            return (localize(string: Constants.customString), customFee)
        default:
            return ("", BigInt.zero())
        }
    }
    
    func updateTransaction() {
        if selectedIndexOfSpeed != nil {
            let feeRate = feeRateForIndex(selectedIndexOfSpeed!)
            transactionDTO.feeRate = feeRate.value
            transactionDTO.feeRateName = feeRate.name
        }
        
        transactionDTO.donationAmount = donationInCrypto
    }
    
    func segueToAmount() {
        if self.availableSumInCrypto == nil || availableSumInCrypto! < 0.0 {
            self.vc?.presentWarning(message: "Wrong wallet data. Please download wallet data again.")
            
            return
        }
        
        if isDonationSwitchedOn != nil && isDonationSwitchedOn! {
            if self.donationInCrypto! > self.availableSumInCrypto!  {
                self.vc?.presentWarning(message: "Your donation more than you have in wallet.\n\nDonation sum: \(self.donationInCrypto!.cryptoValueString(for: transactionDTO.choosenWallet!.blockchain)) \(self.cryptoName)\n Sum in Wallet: \(self.availableSumInCrypto!.cryptoValueString(for: transactionDTO.choosenWallet!.blockchain)) \(self.cryptoName)")
            } else if self.donationInCrypto! == self.availableSumInCrypto! {
                self.vc?.presentWarning(message: "Your donation is equal your wallet sum.\n\nDonation sum: \(self.donationInCrypto!.cryptoValueString(for: transactionDTO.choosenWallet!.blockchain)) \(self.cryptoName)\n Sum in Wallet: \(self.availableSumInCrypto!.cryptoValueString(for: transactionDTO.choosenWallet!.blockchain)) \(self.cryptoName)")
            } else {
                self.vc?.performSegue(withIdentifier: "sendAmountVC", sender: Any.self)
            }
        } else {
            self.vc?.performSegue(withIdentifier: "sendAmountVC", sender: Any.self)
        }
    }
    
    func isPossibleToDonate(_ amountString: String) -> Bool {
        var donationStringForDouble = amountString
        if donationStringForDouble.last == "," {
            donationStringForDouble.removeLast()
        }
        
        let donationInMinimalUnits = donationStringForDouble.convertCryptoAmountStringToMinimalUnits(for: transactionDTO.choosenWallet!.blockchain)
        return donationInMinimalUnits <= availableSumInCrypto!
    }
    
    func changeDonationString(_ toAmount: String?) {
        donationInCryptoString = toAmount
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Sends"
    }
}

extension CustomFeeRateDelegate: CustomFeeRateProtocol {
    func customFeeData(firstValue: BigInt?, secValue: BigInt?) {
        guard firstValue != nil else {
            return
        }
        
        customFee = firstValue!
        vc?.sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(transactionDTO.choosenWallet!.chain)", eventName: customFeeSetuped)
    }

    
    func setPreviousSelected(index: Int?) {
        self.vc?.tableView.selectRow(at: [0,index!], animated: false, scrollPosition: .none)
        self.vc?.tableView.delegate?.tableView!(self.vc!.tableView, didSelectRowAt: [0,index!])
        self.selectedIndexOfSpeed = index!
    }
}
