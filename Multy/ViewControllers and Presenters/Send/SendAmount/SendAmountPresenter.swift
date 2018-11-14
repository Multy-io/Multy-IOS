//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

private typealias CreateTransactionDelegate = SendAmountPresenter

class SendAmountPresenter: NSObject {
    var vc: SendAmountViewController?
    
    private var account = DataManager.shared.realmManager.account
    
    var transactionDTO = TransactionDTO() {
        didSet {
            disassembleTransaction()
        }
    }
    
    // preliminary data
    private var binaryData : BinaryData?
    private var addressData : Dictionary<String, Any>? {
        didSet {
            guard addressData != nil else {
                return
            }
            
            if blockchain == BLOCKCHAIN_BITCOIN {
                transactionDTO.BTCDTO!.newChangeAddress = addressData?["address"] as? String
            }
        }
    }
    var linkedWallet: UserWalletRLM? // for multisig wallets
    
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
    
    var exchangeCourse = exchangeCourseDefault {
        didSet {
            if oldValue != exchangeCourse {
                vc?.updateUI()
            }
        }
    }
    
    var isCrypto = true {
        didSet {
            if oldValue != isCrypto {
                let convertedAmountOldString = convertedAmountString
                var sendAmountOldString = sendAmountString
                if sendAmountOldString.doubleValue == 0 {
                    sendAmountOldString = "0"
                }
                
                convertedAmountString = sendAmountOldString
                sendAmountString = convertedAmountOldString
            }
            vc?.updateUI()
        }
    }
    
    var sendAmountString = "0" {
        didSet {
            vc?.updateUI()
        }
    }
    
    var convertedAmountString = "0" {
        didSet {
            vc?.updateUI()
        }
    }
    
    private var donationAmount : BigInt? {
        get {
            return transactionDTO.donationAmount
        }
    }
    private var feeEstimationInCrypto : BigInt? {
        didSet {
            if blockchain != BLOCKCHAIN_BITCOIN {
                updateTotalSumInCrypto()
            }
        }
    }
    
    private var sendAmountInCryptoMinimalUnits = BigInt.zero() {
        didSet {
            if sendAmountInCryptoMinimalUnits != oldValue {
                updateTotalSumInCrypto()
            }
        }
    }
    
    private var totalSumInCrypto = BigInt.zero() {
        didSet {
            vc?.updateUI()
        }
    }
    
    var totalSumInCryptoString: String {
        return totalSumInCrypto.cryptoValueString(for: blockchain!)
    }
    
    private var totalSumInFiat: BigInt {
        get {
            let result = totalSumInCrypto * exchangeCourse
            return result
        }
    }
    
    var totalSumInFiatString: String {
        return totalSumInFiat.fiatValueString(for: blockchain!)
    }
    
    private var availableSumInCrypto: BigInt {
        get {
            return transactionDTO.choosenWallet!.availableAmount
        }
    }
    
    var availableSumInCryptoString: String {
        get {
            return blockchain != nil ? availableSumInCrypto.cryptoValueString(for: blockchain!) : "0"
        }
    }
    
    var availableSumInFiatString: String {
        get {
            return blockchain != nil ? (availableSumInCrypto * exchangeCourse).fiatValueString(for: blockchain!) : "0"
        }
    }
    
    var maxAllowedToSpendInChoosenCurrencyString: String {
        get {
            return isCrypto ? maxAllowedToSpendInCrypto.cryptoValueString(for: blockchain!) : maxAllowedToSpendInFiat.fiatValueString(for: blockchain!)
        }
    }
    
    private var maxAllowedToSpendInChoosenCurrency: BigInt {
        return isCrypto ? maxAllowedToSpendInCrypto : maxAllowedToSpendInFiat
    }
    
    private var maxAllowedToSpendInCrypto: BigInt {
        get {
            var result = availableSumInCrypto
            if payForCommission && feeEstimationInCrypto != nil {
                result = result - feeEstimationInCrypto!
            }
            
            if donationAmount != nil {
                result = result - donationAmount!
            }
            
            return result
        }
    }
    
    private var maxAllowedToSpendInFiat: BigInt {
        get  {
            return maxAllowedToSpendInCrypto * exchangeCourse
        }
    }
    
    var maxLengthForSum: Int {
        get {
            return transactionDTO.choosenWallet!.blockchain.maxLengthForSum
        }
    }
    
    var payForCommission = true {
        didSet {
            if oldValue != payForCommission {
                
                updateTotalSumInCrypto()
            }
        }
    }
    
    private var rawTransaction = String()
    
    
    
    
    func vcViewDidLoad() {
        createPreliminaryData()
        vc?.configure()
        resetAmount()
        updateTotalSumInCrypto()
    }
    
    func vcViewWillAppear() {
        addNotificationsObservers()
        vc?.showKeyboard()
    }
    
    func vcViewDidLayoutSubviews() {
        vc?.updateConstraints()
        vc?.updateUI()
    }
    
    func vcViewWillDisappear() {
        removeNotificationsObservers()
    }
    
    private func assembleTransaction() {
        let sendAmountString = sendAmountForDoubleString()
        transactionDTO.sendAmount = isCrypto ? sendAmountString : convertedAmountString
        transactionDTO.feeEstimation = feeEstimationInCrypto
        transactionDTO.rawValue = rawTransaction
    }
    
    private func disassembleTransaction() {
        exchangeCourse = transactionDTO.choosenWallet != nil ? transactionDTO.choosenWallet!.exchangeCourse : exchangeCourseDefault
        if blockchain != nil {
            if transactionDTO.sendAmount != nil {
                changeSendAmountString(String(format: "%f", transactionDTO.sendAmount!))
            }
            
            if blockchain == BLOCKCHAIN_ETHEREUM {
                feeEstimationInCrypto = transactionDTO.ETHDTO?.feeAmount
            }
        }
    }
    
    private func sendAmountForDoubleString() -> String {
        var result = sendAmountString
        if result.last == "," {
            result.removeLast()
        }
        return result
    }
    
    private func createPreliminaryData() {
        let core = DataManager.shared.coreLibManager
        let wallet = transactionDTO.choosenWallet!
        binaryData = account!.binaryDataString.createBinaryData()!
        
        if !wallet.isImported  {
            addressData = core.createAddress(blockchainType:    wallet.blockchainType,
                                             walletID:      wallet.walletID.uint32Value,
                                             addressID:     wallet.changeAddressIndex,
                                             binaryData:    &binaryData!)
        }
        
        if transactionDTO.choosenWallet!.isMultiSig {
            DataManager.shared.getWallet(primaryKey: transactionDTO.choosenWallet!.multisigWallet!.linkedWalletID) { [unowned self] in
                switch $0 {
                case .success(let wallet):
                    self.linkedWallet = wallet
                    break;
                case .failure(let errorString):
                    print(errorString)
                    break;
                }
            }
        }
    }
    
    func changeSendAmountString(_ toAmount: String) {
        sendAmountString = toAmount
        sendAmountInCryptoMinimalUnits = isCrypto ? sendAmountForDoubleString().convertCryptoAmountStringToMinimalUnits(in: blockchain!) : sendAmountForDoubleString().convertCryptoAmountStringToMinimalUnits(in: blockchain!) / exchangeCourse
        let convertedAmountInMinimalUnits = isCrypto ? sendAmountInCryptoMinimalUnits * exchangeCourse : sendAmountInCryptoMinimalUnits
        
        convertedAmountString = isCrypto ? convertedAmountInMinimalUnits.fiatValueString(for: blockchain!) : convertedAmountInMinimalUnits.cryptoValueString(for: blockchain!)
        vc?.updateUI()
    }
    
    func setSumToMaxAllowed() {
        payForCommission = false
        sendAmountInCryptoMinimalUnits = maxAllowedToSpendInCrypto
        sendAmountString = isCrypto ? sendAmountInCryptoMinimalUnits.cryptoValueString(for: blockchain!) : (sendAmountInCryptoMinimalUnits * exchangeCourse).fiatValueString(for: blockchain!)
        convertedAmountString = isCrypto ? (sendAmountInCryptoMinimalUnits * exchangeCourse).fiatValueString(for: blockchain!) : sendAmountInCryptoMinimalUnits.cryptoValueString(for: blockchain!)
    }
    
    func resetAmount() {
        changeSendAmountString("0")
    }
    
    func goToFinish() {
        if estimateTransactionAndValidation() {
            assembleTransaction()
            vc?.segueToFinish()
        }
    }
    
    func isPossibleToSpendAmount(_ amountString: String) -> Bool {
        var sendAmountStringForDouble = amountString
        if amountString.last == "," {
            sendAmountStringForDouble.removeLast()
        }
        
        let amountInMinimalUnits = isCrypto ? sendAmountStringForDouble.convertCryptoAmountStringToMinimalUnits(in: blockchain!) : String(format: "%f", (sendAmountStringForDouble.doubleValue / exchangeCourse)).convertCryptoAmountStringToMinimalUnits(in: blockchain!)
        return amountInMinimalUnits <= maxAllowedToSpendInCrypto
    }
    
    func updateTotalSumInCrypto() {
        var result = BigInt.zero()
        let isTxValid = estimateTransactionAndValidation()
        if !isTxValid {
            var message = rawTransaction
            
            if message.count > 0, vc != nil, transactionDTO.choosenWallet != nil && sendAmountInCryptoMinimalUnits > BigInt.zero() {
                if message.hasPrefix("BigInt value is not representable as") {
                    message = vc!.localize(string: Constants.youEnteredTooSmallAmountString)
                } else if message.hasPrefix("Transaction is trying to spend more than available in inputs") {
                    message = vc!.localize(string: Constants.youTryingSpendMoreThenHaveString)
                }
                
                let alert = UIAlertController(title: vc!.localize(string: Constants.errorString), message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in }))
                vc!.present(alert, animated: true, completion: nil)
                
                totalSumInCrypto = BigInt.zero()
                vc!.sendAnalyticsEvent(screenName: "\(screenSendAmountWithChain)\(transactionDTO.choosenWallet!.chain)", eventName: transactionErr)
                
                return
            }
        }
        
        result = sendAmountInCryptoMinimalUnits
        
        if result.isZero {
            totalSumInCrypto = BigInt.zero()
        } else {
            if payForCommission {
                if feeEstimationInCrypto != nil {
                    result = result + feeEstimationInCrypto!
                    
                    if donationAmount != nil {
                        result = result + donationAmount!
                    }
                }
            }
            
            if result > availableSumInCrypto {
                result = availableSumInCrypto
            }
            
            totalSumInCrypto = result
        }
    }
    
    func swapCurrencies() {
        isCrypto = !isCrypto
    }
    
    private func estimateTransactionAndValidation() -> Bool {
        switch blockchain {
        case BLOCKCHAIN_BITCOIN:
            return estimateBTCTransactionAndValidation()
        case BLOCKCHAIN_ETHEREUM:
            return estimateETHTransactionAndValidation()
            
        default:
            return false
        }
    }
    
    func addNotificationsObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillEnterForeground(_:)), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    func removeNotificationsObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            vc?.keyboardHeight = keyboardSize.height
        }
    }
    
    @objc func applicationWillEnterForeground(_ notification: NSNotification) {
        vc?.showKeyboard()
    }
}

extension CreateTransactionDelegate {
    func estimateBTCTransactionAndValidation() -> Bool {
        let blockchaintType = BlockchainType.create(wallet: transactionDTO.choosenWallet!)
        if blockchaintType.blockchain != BLOCKCHAIN_BITCOIN {
            print("\n\n\nnot right screen\n\n\n")
        }
        
        let pointer = addressData?["addressPointer"] as? UnsafeMutablePointer<OpaquePointer?>
        
        guard pointer != nil, blockchain != nil, transactionDTO.sendAddress != nil, transactionDTO.BTCDTO != nil, transactionDTO.BTCDTO!.feePerByte != nil, transactionDTO.choosenWallet != nil, binaryData != nil else {
            return false
        }
        
        let trData = DataManager.shared.coreLibManager.createTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                                         sendAddress: transactionDTO.sendAddress!,
                                                                         sendAmountString: sendAmountInCryptoMinimalUnits.cryptoValueString(for: blockchain!),
                                                                         feePerByteAmount: transactionDTO.BTCDTO!.feePerByte!.stringValue,
            isDonationExists: transactionDTO.donationAmount != nil && !transactionDTO.donationAmount!.isZero,
            donationAmount: transactionDTO.donationAmount?.cryptoValueString(for: blockchain!) ?? BigInt.zero().stringValue,
            isPayCommission: payForCommission,
            wallet: transactionDTO.choosenWallet!,
            binaryData: &binaryData!,
            inputs: transactionDTO.choosenWallet!.addresses)
        
        feeEstimationInCrypto = BigInt(trData.2)
        rawTransaction = trData.0
        
        return trData.1 >= 0
    }
    
    func estimateETHTransactionAndValidation() -> Bool {
        var sendAmount = BigInt.zero()
        if payForCommission {
            sendAmount = sendAmountInCryptoMinimalUnits
        } else {
            if transactionDTO.choosenWallet!.isMultiSig {
                sendAmount = sendAmountInCryptoMinimalUnits
            } else {
                if sendAmountInCryptoMinimalUnits > feeEstimationInCrypto {
                    sendAmount = sendAmountInCryptoMinimalUnits - feeEstimationInCrypto
                } else {
                    rawTransaction = "Amount too low!"
                    return false
                }
            }
        }
        
        let pointer: UnsafeMutablePointer<OpaquePointer?>?
        if transactionDTO.choosenWallet!.isImported {
            let blockchainType = BlockchainType.create(wallet: transactionDTO.choosenWallet!)
            let privatekey = transactionDTO.choosenWallet!.importedPrivateKey
            let walletInfo = DataManager.shared.coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: privatekey)
            switch walletInfo {
            case .success(let value):
                pointer = value["pointer"] as? UnsafeMutablePointer<OpaquePointer?>
            case .failure(let error):
                print(error)
                
                return false
            }
        } else {
            pointer = addressData?["addressPointer"] as? UnsafeMutablePointer<OpaquePointer?>
        }
        
        if transactionDTO.choosenWallet!.isMultiSig {
            if linkedWallet == nil {
                rawTransaction = "Error"
                
                return false
            }
            
            guard binaryData != nil,  linkedWallet != nil, transactionDTO.choosenWallet != nil, transactionDTO.sendAddress != nil else {
                return false
            }
            
            let trData = DataManager.shared.createMultiSigTx(binaryData: &binaryData!,
                                                             wallet: linkedWallet!,
                                                             sendFromAddress: transactionDTO.choosenWallet!.address,
                                                             sendAmountString: sendAmount.stringValue,
                                                             sendToAddress: transactionDTO.sendAddress!,
                                                             msWalletBalance: transactionDTO.choosenWallet!.availableAmount.stringValue,
                                                             gasPriceString: transactionDTO.ETHDTO?.gasPrice?.stringValue ?? "0",
                                                             gasLimitString: transactionDTO.ETHDTO?.gasLimit?.stringValue ?? "0")
            
            rawTransaction = trData.message
            
            return trData.isTransactionCorrect
        } else {
            guard pointer != nil, transactionDTO.sendAddress != nil, transactionDTO.choosenWallet != nil, transactionDTO.choosenWallet!.ethWallet != nil else {
                return false
            }
            
            let trData = DataManager.shared.coreLibManager.createEtherTransaction(addressPointer: pointer!,
                                                                                  sendAddress: transactionDTO.sendAddress!,
                                                                                  sendAmountString: sendAmount.stringValue,
                                                                                  nonce: transactionDTO.choosenWallet!.ethWallet!.nonce.intValue,
                                                                                  balanceAmount: "\(transactionDTO.choosenWallet!.ethWallet!.balance)",
                ethereumChainID: UInt32(transactionDTO.choosenWallet!.blockchainType.net_type),
                gasPrice: transactionDTO.ETHDTO?.gasPrice?.stringValue ?? "0",
                gasLimit: transactionDTO.ETHDTO?.gasLimit?.stringValue ?? "0")
            
            rawTransaction = trData.message
            
            return trData.isTransactionCorrect
        }
    }
}
