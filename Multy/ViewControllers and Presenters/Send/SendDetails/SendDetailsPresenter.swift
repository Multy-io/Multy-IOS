//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

private typealias LocalizeDelegate = SendDetailsPresenter
private typealias CustomFeeRateDelegate = SendDetailsPresenter
private typealias CreateTransactionDelegate = SendDetailsPresenter

class SendDetailsPresenter: NSObject {
    
    var vc: SendDetailsViewController?
    var transactionDTO = TransactionDTO() {
        didSet {
            availableSumInCrypto = transactionDTO.assetsWallet.availableAmount
            availableSumInFiat = transactionDTO.assetsWallet.availableAmountInFiat
            cryptoName = transactionDTO.assetsWallet.assetShortName
            fiatName = transactionDTO.choosenWallet!.fiatName
            feeRates = defaultFeeRates()
            
            if transactionDTO.isTokenTransfer {
                sendTXMode = SendTXMode.erc20
                tokenWallet = transactionDTO.choosenWallet
            }
           
            assetsWallet = transactionDTO.assetsWallet
            blockchainType = transactionDTO.blockchainType!
            blockchain = blockchainType.blockchain
            blockchainObject = (sendTXMode == SendTXMode.crypto) ? blockchain : tokenWallet!.token
            sendCryptoBlockchainType = (blockchain == BLOCKCHAIN_ERC20) ? BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: blockchainType.net_type) : blockchainType
            sendCryptoBlockchain = sendCryptoBlockchainType.blockchain
        }
    }
    
    var availableSumInCrypto    : BigInt?
    var availableSumInFiat      : BigInt?
    
    var assetsWallet = UserWalletRLM()
    private var addressData : Dictionary<String, Any>?
    private var binaryData : BinaryData?
    var blockchainObject: Any?
    var sendTXMode = SendTXMode.crypto
    var tokenWallet: UserWalletRLM?
    var blockchainType = BlockchainType(blockchain: BLOCKCHAIN_BITCOIN, net_type: 0)
    var blockchain = BLOCKCHAIN_BITCOIN
    var sendCryptoBlockchainType = BlockchainType(blockchain: BLOCKCHAIN_BITCOIN, net_type: 0)
    var sendCryptoBlockchain = BLOCKCHAIN_BITCOIN
    private var rawTransaction = String()
    var linkedWallet: UserWalletRLM? // for multisig wallets
    
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
        
        if transactionDTO.choosenWallet!.isMultiSig {
            DataManager.shared.getWallet(primaryKey: transactionDTO.choosenWallet!.multisigWallet!.linkedWalletID) { (result) in
                switch result {
                case .success(let linkedWallet):
                    self.linkedWallet = linkedWallet
                case .failure:
                    print("error while getting linked wallet")
                }
            }
        }
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
                                        
                                        if let gasLimitForMS = dict?["gaslimit"] as? String {
                                            self!.transactionDTO.ETHDTO!.gasLimit = BigInt(gasLimitForMS)
                                        }
                                        
                                        if dict != nil, let fees = dict!["speeds"] as? NSDictionary {
                                            self!.feeRates = fees
                                        } else {
                                            print("Did failed getting feeRate")
                                        }
                                        
                                        
        })
        
        if transactionDTO.blockchain == BLOCKCHAIN_ERC20 {
            transactionDTO.ETHDTO!.gasLimit = BigInt("\(plainERC20TxGasLimit)")
        } else if transactionDTO.blockchain == BLOCKCHAIN_ETHEREUM {
            if transactionDTO.choosenWallet!.isMultiSig {
                DataManager.shared.estimation(for: transactionDTO.choosenWallet!.address) { [weak self] in
                    switch $0 {
                    case .success(let value):
                        guard self != nil else {
                            return
                        }
                        
                        let limit = value["submitTransaction"] as! NSNumber
                        self!.transactionDTO.ETHDTO!.gasLimit = BigInt("\(limit)")
                        break
                    case .failure(let error):
                        print(error)
                        break
                    }
                }
            } else {
                transactionDTO.ETHDTO!.gasLimit = BigInt("\(21_000)")
            }
        }
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
    
    func isWalletAmountEnough() -> Bool {
        return estimateTransactionAndValidationResult()
    }
    
    private func estimateTransactionAndValidationResult() -> Bool {
        let dm = DataManager.shared
        binaryData = dm.realmManager.account!.binaryDataString.createBinaryData()!
        
        if !assetsWallet.isImported  {
            addressData = dm.createAddress(blockchainType:sendCryptoBlockchainType,
                                           walletID:      assetsWallet.walletID.uint32Value,
                                           addressID:     assetsWallet.changeAddressIndex,
                                           binaryData:    &binaryData!)
        }

        
        switch transactionDTO.assetsWallet.blockchain {
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

//FIXME: combine this extension with analogous from SendAmountPresenter
extension CreateTransactionDelegate {
    func estimateBTCTransactionAndValidation() -> Bool {
        let blockchaintType = BlockchainType.create(wallet: transactionDTO.choosenWallet!)
        
        if blockchaintType.blockchain != BLOCKCHAIN_BITCOIN {
            print("\n\n\nnot right screen\n\n\n")
        }
        
        let pointer = addressData?["addressPointer"] as? UnsafeMutablePointer<OpaquePointer?>
        
        guard pointer != nil, transactionDTO.sendAddress != nil, transactionDTO.BTCDTO != nil, transactionDTO.BTCDTO!.feePerByte != nil, transactionDTO.choosenWallet != nil, binaryData != nil else {
            return false
        }
        
        let trData = DataManager.shared.createTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                          sendAddress: transactionDTO.sendAddress!,
                                                          sendAmountString: "0,00000548",
                                                          feePerByteAmount: transactionDTO.BTCDTO!.feePerByte!.stringValue,
                                                          isDonationExists: transactionDTO.donationAmount != nil && !transactionDTO.donationAmount!.isZero,
                                                          donationAmount: transactionDTO.donationAmount?.cryptoValueString(for: blockchainObject) ?? BigInt.zero().stringValue,
                                                          isPayCommission: true,
                                                          wallet: transactionDTO.choosenWallet!,
                                                          binaryData: &binaryData!,
                                                          inputs: transactionDTO.choosenWallet!.addresses)
        
//        feeEstimationInCrypto = BigInt(trData.2)
        rawTransaction = trData.0
        
        return trData.1 >= 0
    }
    
    func estimateETHTransactionAndValidation() -> Bool {
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
                                                             sendAmountString: "0",
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
                                                                 sendAmountString: "0",
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
                                                                   sendTokenAmountString: "0",
                                                                   destinationAddress: transactionDTO.sendAddress!,
                                                                   gasPriceAmountString: transactionDTO.ETHDTO!.gasPrice.stringValue,
                                                                   gasLimitAmountString: transactionDTO.ETHDTO!.gasLimit.stringValue)
        
        rawTransaction = rawTX.message
        
        return rawTX.isTransactionCorrect
    }
}
