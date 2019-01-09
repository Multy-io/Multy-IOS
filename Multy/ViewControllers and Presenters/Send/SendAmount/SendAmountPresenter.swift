//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
import Alamofire

enum SendTXMode {
    case crypto
    case erc20
}

private typealias CreateTransactionDelegate = SendAmountPresenter

class SendAmountPresenter: NSObject {
    var vc: SendAmountViewController?
    
    private var account = DataManager.shared.realmManager.account
    
    var transactionDTO = TransactionDTO() {
        didSet {
            
            
            assetsWallet = transactionDTO.assetsWallet
            
            blockchainType = transactionDTO.blockchainType!
            blockchain = blockchainType.blockchain
            
            if transactionDTO.isTokenTransfer {
                sendTXMode = SendTXMode.erc20
                tokenWallet = transactionDTO.choosenWallet
            }
            
            blockchainObject = (sendTXMode == SendTXMode.crypto) ? blockchain : tokenWallet!.token
            
            exchangeCourse = transactionDTO.choosenWallet!.exchangeCourse
            
            sendCryptoBlockchainType = (blockchain == BLOCKCHAIN_ERC20) ? BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: blockchainType.net_type) : blockchainType
            sendCryptoBlockchain = sendCryptoBlockchainType.blockchain
            
            cryptoName = transactionDTO.choosenWallet!.assetShortName
            
            maxPrecision = transactionDTO.choosenWallet!.assetPrecision
            
            disassembleTransaction()
        }
    }
    
    var sendFromThisScreen = false
    var isPayForComissionCanBeChanged = true
    
    var assetsWallet = UserWalletRLM()
    var tokenWallet: UserWalletRLM?
    var sendTXMode = SendTXMode.crypto
    var blockchainObject: Any?
    
    var sendCryptoBlockchainType = BlockchainType(blockchain: BLOCKCHAIN_BITCOIN, net_type: 0)
    var sendCryptoBlockchain = BLOCKCHAIN_BITCOIN
    
    var maxPrecision = 0
    
    var estimationInfo: NSDictionary?
    
    func getEstimation(for operation: String) -> String {
        let value = self.estimationInfo?[operation] as? NSNumber
        return value == nil ? "\(400_000)" : "\(value!)"
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
    
    var cryptoName = String()
    
    var fiatName: String {
        get {
            let result = transactionDTO.choosenWallet?.fiatName
            return result != nil ? result! : ""
        }
    }
    
    var blockchainType = BlockchainType(blockchain: BLOCKCHAIN_BITCOIN, net_type: 0)
    var blockchain = BLOCKCHAIN_BITCOIN
    
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
        return totalSumInCrypto.cryptoValueString(for: blockchainObject)
    }
    
    private var totalSumInFiat: BigInt {
        get {
            let result = totalSumInCrypto * exchangeCourse
            return result
        }
    }
    
    var totalSumInFiatString: String {
        return totalSumInFiat.fiatValueString(for: blockchain)
    }
    
    private var availableSumInCrypto: BigInt {
        get {
            return transactionDTO.choosenWallet!.availableAmount
        }
    }
    
    var availableSumInCryptoString: String {
        get {
            return blockchain != nil ? availableSumInCrypto.cryptoValueString(for: blockchainObject) : "0"
        }
    }
    
    var availableSumInFiatString: String {
        get {
            return blockchain != nil ? (availableSumInCrypto * exchangeCourse).fiatValueString(for: blockchain) : "0"
        }
    }
    
    var maxAllowedToSpendInChoosenCurrencyString: String {
        get {
            return isCrypto ? maxAllowedToSpendInCrypto.cryptoValueString(for: blockchainObject) : maxAllowedToSpendInFiat.fiatValueString(for: blockchain)
        }
    }
    
    private var maxAllowedToSpendInChoosenCurrency: BigInt {
        return isCrypto ? maxAllowedToSpendInCrypto : maxAllowedToSpendInFiat
    }
    
    private var maxAllowedToSpendInCrypto: BigInt {
        get {
            var result = availableSumInCrypto
            if sendTXMode == .erc20 {
                return result
            }
            
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
        changeSendAmountString(sendAmountString)
        updateTotalSumInCrypto()
    }
    
    func vcViewWillAppear() {
        addNotificationsObservers()
        vc?.showKeyboard()
        vc?.prepareButtonsHolderUI()
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
        transactionDTO.sendAmountString = isCrypto ? sendAmountString : convertedAmountString
        transactionDTO.feeEstimation = feeEstimationInCrypto
        transactionDTO.rawValue = rawTransaction
    }
    
    private func disassembleTransaction() {
        exchangeCourse = transactionDTO.choosenWallet != nil ? transactionDTO.choosenWallet!.exchangeCourse : exchangeCourseDefault
        if transactionDTO.sendAmountString != nil {
            changeSendAmountString(transactionDTO.sendAmountString!)
        }
        
//        if transactionDTO.blockchain == BLOCKCHAIN_ETHEREUM {
//            if transactionDTO.choosenWallet!.isMultiSig {
//                DataManager.shared.estimation(for: transactionDTO.choosenWallet!.address) { [weak self] in
//                    switch $0 {
//                    case .success(let value):
//                        guard self != nil else {
//                            return
//                        }
//                        
//                        let limit = value["submitTransaction"] as! String
//                        self!.transactionDTO.ETHDTO!.gasLimit = BigInt(limit)
//                        self!.feeEstimationInCrypto = self!.transactionDTO.ETHDTO?.feeAmount
//                        break
//                    case .failure(let error):
//                        print(error)
//                        break
//                    }
//                }
//            } else {
//                transactionDTO.ETHDTO!.gasLimit = BigInt("\(plainTxGasLimit)")
//                feeEstimationInCrypto = transactionDTO.ETHDTO?.feeAmount
//            }
//        } else if transactionDTO.blockchain == BLOCKCHAIN_ERC20 {
//            transactionDTO.ETHDTO!.gasLimit = BigInt("\(plainERC20TxGasLimit)")
//            feeEstimationInCrypto = transactionDTO.ETHDTO?.feeAmount
//        }
        
        if transactionDTO.blockchain == BLOCKCHAIN_ETHEREUM || transactionDTO.blockchain == BLOCKCHAIN_ERC20 {
            feeEstimationInCrypto = transactionDTO.ETHDTO?.feeAmount
        }
    }
    
    private func sendAmountForDoubleString() -> String {
        var result = sendAmountString
        if result.last == "," || result.last == "." {
            result.removeLast()
        }
        return result
    }
    
    private func createPreliminaryData() {
        let dm = DataManager.shared
        binaryData = account!.binaryDataString.createBinaryData()!
        
        if !assetsWallet.isImported  {
            addressData = dm.createAddress(blockchainType:sendCryptoBlockchainType,
                                           walletID:      assetsWallet.walletID.uint32Value,
                                           addressID:     assetsWallet.changeAddressIndex,
                                           binaryData:    &binaryData!)
        }
        
        if transactionDTO.choosenWallet!.isMultiSig {
            dm.estimation(for: assetsWallet.address) { [unowned self] in
                switch $0 {
                case .success(let value):
                    self.estimationInfo = value
                    
                    let limit = self.getEstimation(for: "submitTransaction")
                    self.transactionDTO.ETHDTO?.gasLimit = BigInt(limit)
                    
                    break
                case .failure(let error):
                    print(error)
                    break
                }
            }
            
            dm.getWallet(primaryKey: assetsWallet.multisigWallet!.linkedWalletID) { [unowned self] in
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
        sendAmountInCryptoMinimalUnits = isCrypto ? sendAmountForDoubleString().convertCryptoAmountStringToMinimalUnits(for: blockchainObject) : sendAmountForDoubleString().convertCryptoAmountStringToMinimalUnits(for: blockchainObject) / exchangeCourse
        let convertedAmountInMinimalUnits = isCrypto ? sendAmountInCryptoMinimalUnits * exchangeCourse : sendAmountInCryptoMinimalUnits
        
        convertedAmountString = isCrypto ? convertedAmountInMinimalUnits.fiatValueString(for: blockchain) : convertedAmountInMinimalUnits.cryptoValueString(for: blockchainObject)
        vc?.updateUI()
    }
    
    func setSumToMaxAllowed() {
        payForCommission = false
        sendAmountInCryptoMinimalUnits = maxAllowedToSpendInCrypto
        sendAmountString = isCrypto ? sendAmountInCryptoMinimalUnits.cryptoValueString(for: blockchainObject) : (sendAmountInCryptoMinimalUnits * exchangeCourse).fiatValueString(for: blockchain)
        convertedAmountString = isCrypto ? (sendAmountInCryptoMinimalUnits * exchangeCourse).fiatValueString(for: blockchain) : sendAmountInCryptoMinimalUnits.cryptoValueString(for: blockchainObject)
    }
    
    func resetAmount() {
        changeSendAmountString("0")
    }
    
    func goToFinish() {
        let isvalid = estimateTransactionAndValidation()
        if isvalid && sendAmountInCryptoMinimalUnits.isNonZero {
            assembleTransaction()
            vc?.segueToFinish()
        } else {
            if isvalid == false {
                vc!.presentAlert(with: rawTransaction)
            } else {
                vc!.presentAlert(with: vc!.localize(string: Constants.enterNonZeroAmountString))
            }
        }
    }
    
    func isPossibleToSpendAmount(_ amountString: String) -> Bool {
        var sendAmountStringForDouble = amountString
        if amountString.last == "," || amountString.last == "." {
            sendAmountStringForDouble.removeLast()
        }
        
        let amountInMinimalUnits = isCrypto ? sendAmountStringForDouble.convertCryptoAmountStringToMinimalUnits(for: blockchainObject) : sendAmountStringForDouble.convertCryptoAmountStringToMinimalUnits(for: blockchainObject) / exchangeCourse
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
                } else if message.hasPrefix("Transaction is trying to spend more than available") {
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
            if sendTXMode != .erc20 {
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
            } else {
                //erc20 section
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
        case BLOCKCHAIN_ERC20:
            return estimateTokenTransactionAndValidation()
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
        
        let trData = DataManager.shared.createTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                          sendAddress: transactionDTO.sendAddress!,
                                                          sendAmountString: sendAmountInCryptoMinimalUnits.cryptoValueString(for: blockchainObject),
                                                          feePerByteAmount: transactionDTO.BTCDTO!.feePerByte!.stringValue,
                                                          isDonationExists: transactionDTO.donationAmount != nil && !transactionDTO.donationAmount!.isZero,
                                                          donationAmount: transactionDTO.donationAmount?.cryptoValueString(for: blockchainObject) ?? BigInt.zero().stringValue,
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
        
        if transactionDTO.choosenWallet!.isMultiSig {
            if linkedWallet == nil {
                rawTransaction = "Error"
                
                return false
            }
            
            guard binaryData != nil,  linkedWallet != nil, transactionDTO.choosenWallet != nil, transactionDTO.sendAddress != nil else {
                return false
            }
            
            let trData = DataManager.shared.createMultiSigTx(wallet: linkedWallet!,
                                                             sendFromAddress: transactionDTO.choosenWallet!.address,
                                                             sendAmountString: sendAmount.stringValue,
                                                             sendToAddress: transactionDTO.sendAddress!,
                                                             msWalletBalance: transactionDTO.choosenWallet!.availableAmount.stringValue,
                                                             gasPriceString: transactionDTO.ETHDTO!.gasPrice.stringValue,
                                                             gasLimitString: transactionDTO.ETHDTO!.gasLimit.stringValue)
            
//            let trData2 = DataManager.shared.createMultiSigTx(binaryData: &binaryData!,
//                                                             wallet: linkedWallet!,
//                                                             sendFromAddress: transactionDTO.choosenWallet!.address,
//                                                             sendAmountString: sendAmount.stringValue,
//                                                             sendToAddress: transactionDTO.sendAddress!,
//                                                             msWalletBalance: transactionDTO.choosenWallet!.availableAmount.stringValue,
//                                                             gasPriceString: transactionDTO.ETHDTO!.gasPrice.stringValue,
//                                                             gasLimitString: transactionDTO.ETHDTO!.gasLimit.stringValue)
            
            rawTransaction = trData.message
            
            return trData.isTransactionCorrect
        } else {
            guard transactionDTO.sendAddress != nil, transactionDTO.choosenWallet != nil, transactionDTO.choosenWallet!.ethWallet != nil else {
                return false
            }
            
            let trData = DataManager.shared.createETHTransaction(wallet: assetsWallet,
                                                                 sendAmountString: sendAmount.stringValue,
                                                                 destinationAddress: transactionDTO.sendAddress!,
                                                                 gasPriceAmountString: transactionDTO.ETHDTO!.gasPrice.stringValue,
                                                                 gasLimitAmountString: transactionDTO.ETHDTO!.gasLimit.stringValue)
            
//            let trData = DataManager.shared.coreLibManager.createEtherTransaction(addressPointer: pointer!,
//                                                                                  sendAddress: transactionDTO.sendAddress!,
//                                                                                  sendAmountString: sendAmount.stringValue,
//                                                                                  nonce: transactionDTO.choosenWallet!.ethWallet!.nonce.intValue,
//                                                                                  balanceAmount: "\(transactionDTO.choosenWallet!.ethWallet!.balance)",
//                ethereumChainID: UInt32(transactionDTO.choosenWallet!.blockchainType.net_type),
//                gasPrice: transactionDTO.ETHDTO!.gasPrice.stringValue,
//                gasLimit: "21000") // transactionDTO.ETHDTO!.gasLimit.stringValue)
            
            rawTransaction = trData.message
            
            return trData.isTransactionCorrect
        }
    }
    
    func estimateTokenTransactionAndValidation() -> Bool {
        let rawTX = DataManager.shared.createERC20TokenTransaction(wallet: assetsWallet,
                                                                   tokenWallet: tokenWallet!,
                                                                   sendTokenAmountString: totalSumInCrypto.stringValue,
                                                                   destinationAddress: transactionDTO.sendAddress!,
                                                                   gasPriceAmountString: transactionDTO.ETHDTO!.gasPrice.stringValue,
                                                                   gasLimitAmountString: transactionDTO.ETHDTO!.gasLimit.stringValue)
        
        rawTransaction = rawTX.message
        
        return rawTX.isTransactionCorrect
    }
    
    func sendTx() {
        if estimateTransactionAndValidation() && sendAmountInCryptoMinimalUnits.isNonZero {
            assembleTransaction()
            
            self.createRecentAddress()
            
            let params = createTXParameters()
            
            DataManager.shared.sendHDTransaction(transactionParameters: params) { [unowned self] (dict, error) in
                print("---------\(dict)")
                
                if error != nil {
                    self.vc?.sendingTxDidFailed(error!)
                    return
                }
                
                if dict!["code"] as! Int == 200 {
                    self.vc?.goToSendingSuceededScreen()
                } else {
                    self.vc?.sendingTxDidFailed(error!)
                }
            }
        }
    }
    
    func createTXParameters() -> Parameters {
        let wallet = transactionDTO.assetsWallet
        let newAddress = wallet.shouldCreateNewAddressAfterTransaction ? transactionDTO.BTCDTO!.newChangeAddress! : ""
        let addressIndex = wallet.blockchain == BLOCKCHAIN_ETHEREUM ? 0 : wallet.addresses.count
        
        let newAddressParams = [
            "walletindex"   : wallet.walletID.intValue,
            "address"       : newAddress,
            "addressindex"  : addressIndex,
            "transaction"   : transactionDTO.rawValue!,
            "ishd"          : NSNumber(booleanLiteral: wallet.shouldCreateNewAddressAfterTransaction)
            ] as [String : Any]
        
        let params = [
            "currencyid": wallet.chain,
            "networkid" : wallet.chainType,
            "payload"   : newAddressParams
            ] as [String : Any]
        
        return params
    }
    
    func createRecentAddress() {
        let blockchainType = BlockchainType.create(wallet: transactionDTO.choosenWallet!)
        RealmManager.shared.writeOrUpdateRecentAddress(blockchainType: blockchainType,
                                                       address: transactionDTO.sendAddress!,
                                                       date: Date())
    }
}
