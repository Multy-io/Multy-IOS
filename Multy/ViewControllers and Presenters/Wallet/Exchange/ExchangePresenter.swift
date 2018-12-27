//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = ExchangePresenter

enum ExchangeMarket: String {
    case
        changelly = "Changelly",
        quickex = "Quickex"
}

struct MarketInfo {
    var rate = Double(exactly: 1)!
    var limit = Double()
    var min = Double()
    var pairString = String()
    
    mutating func updateMarketInfo(dict: NSDictionary) {
        rate = dict["rate"] as! Double
        limit = dict["limit"] as! Double
        min = dict["min"] as! Double
        pairString = dict["pair"] as! String
    }
}

class ExchangePresenter: NSObject, SendWalletProtocol, AnalyticsProtocol {
    var slideGradient: CAGradientLayer?
    var exchangeMarket = ExchangeMarket.changelly
    var marketInfo = MarketInfo()
    var minimalValueString = String() {
        didSet {
            if minimalValueString.isEmpty {
                exchangeVC!.minimumAmountLabel.text = "MIN: \(localize(string: Constants.notDeterminedString))"
            } else {
                exchangeVC!.minimumAmountLabel.text = "MIN: \(minimalValueString) \(walletFromSending!.assetShortName)"
            }
        }
    }
    
    var exchangeVC: ExchangeViewController?
    var supportedTokens = Array<TokenRLM>()
    var walletFromSending: UserWalletRLM? {
        didSet {
            updateUI()
            
            if walletFromSending == nil {
                return
            }
            
            if walletFromSending!.isTokenWallet {
                sendObject = walletFromSending!.token
            } else {
                sendObject = walletFromSending?.blockchain
            }
            
            feeRate = walletFromSending!.blockchain.defaultfeeRate
            gasLimit = walletFromSending!.blockchain.defaultGasLimit
        }
    }
    
    var feeRate = "1"
    var gasLimit = "\(1_000_000_000)"
    var isSendMax = false

    var walletToReceive: UserWalletRLM? {
        didSet {
            if walletToReceive!.isTokenWallet {
                receiveObject = walletToReceive!.token
            } else {
                receiveObject = walletToReceive!.blockchain
            }
            
            getMarketInfo()
            updateReceiveSection()
            enableUI()
            checkMinAmountExchange(from: walletFromSending!.blockchain.shortName,
                                   to: walletToReceive!.blockchain.shortName)
        }
    }
    
    var sendObject: Any?
    var receiveObject: Any?
    
    func updateUI() {
        exchangeVC?.sendingImg.image = UIImage(named: walletFromSending!.blockchainType.iconString)
        if walletFromSending!.isTokenWallet {
            exchangeVC?.sendingImg.moa.url = walletFromSending?.token?.tokenImageURLString
            exchangeVC?.sendingFiatValueTF.disableView()
        }
        exchangeVC?.sendingMaxBtn.setTitle("MAX \(walletFromSending!.availableAmountString) \(walletFromSending!.blockchain.shortName)", for: .normal)
        exchangeVC?.sendingCryptoName.text = walletFromSending?.assetShortName
        setEndValueToSend()
    }
    
    func setEndValueToSend() {
        exchangeVC?.summarySendingWalletNameLbl.text = walletFromSending?.assetWalletName
        exchangeVC?.summarySendingCryptoValueLbl.text = exchangeVC!.sendingCryptoValueTF.text
        exchangeVC?.summarySendingCryptoNameLbl.text = walletFromSending?.assetShortName
        exchangeVC?.summarySendingImg.image = UIImage(named: walletFromSending!.blockchainType.iconString)
        if walletFromSending!.isTokenWallet {
            exchangeVC?.summarySendingImg.moa.url = walletFromSending?.token?.tokenImageURLString
            exchangeVC?.summarySendingFiatLbl.isHidden = true
        }
        exchangeVC?.summarySendingFiatLbl.text = exchangeVC!.sendingFiatValueTF.text!
    }
    
    func updateReceiveSection() {
        exchangeVC?.receiveCryptoImg.image = UIImage(named: walletToReceive!.blockchainType.iconString)
        if walletToReceive!.isTokenWallet {
            exchangeVC?.receiveCryptoImg.moa.url = walletToReceive?.token?.tokenImageURLString
        }
        exchangeVC?.receiveCryptoNameLbl.text = walletToReceive!.assetShortName
        makeBlockchainRelation()
        setEndValueToReceive()
    }
    
    func setEndValueToReceive() {
        exchangeVC?.summaryReceiveWalletNameLbl.text = walletToReceive!.assetWalletName
        exchangeVC?.summaryReceiveImg.image = UIImage(named: walletToReceive!.blockchainType.iconString)
        if walletToReceive!.isTokenWallet {
            exchangeVC?.summaryReceiveImg.moa.url = walletToReceive?.token?.tokenImageURLString
            exchangeVC?.summaryReceiveFiatLbl.isHidden = true
        }
        exchangeVC?.summaryReceiveCryptoValueLbl.text = exchangeVC?.receiveCryptoValueTF.text
        exchangeVC?.summaryReceiveCryptoNameLbl.text = walletToReceive!.assetShortName
        exchangeVC?.summaryReceiveFiatLbl.text = exchangeVC?.receiveFiatValueTF.text
    }
    
    func makeBlockchainRelation() {
        let relationString = String(marketInfo.rate).showString(8) //String(walletFromSending!.exchangeCourse / walletToReceive!.exchangeCourse).showString(8)
        exchangeVC?.sendToReceiveRelation.text = "1 " + walletFromSending!.assetShortName + "= " + relationString + " " + walletToReceive!.assetShortName
    }
    
    func enableUI() {
        if !walletToReceive!.isTokenWallet {
            exchangeVC?.receiveFiatValueTF.isHidden = false
            exchangeVC?.receiveFiatValueTF.isUserInteractionEnabled = true
            exchangeVC?.receiveFiatValueTF.textColor = .black
            
            exchangeVC!.summaryReceiveFiatLbl.isHidden = true
        } else {
            exchangeVC?.receiveFiatValueTF.isHidden = true
        }
        
        if !walletFromSending!.isTokenWallet {
            exchangeVC?.sendingFiatValueTF.isHidden = false
            exchangeVC?.sendingFiatValueTF.isUserInteractionEnabled = true
            exchangeVC?.sendingFiatValueTF.textColor = .black
            
            exchangeVC!.summaryReceiveFiatLbl.isHidden = true
        } else {
            exchangeVC!.summaryReceiveFiatLbl.isHidden = true
        }
        
        exchangeVC?.sendingMaxBtn.isUserInteractionEnabled = true
        
        exchangeVC?.sendingCryptoValueTF.isUserInteractionEnabled = true
        exchangeVC?.receiveCryptoValueTF.isUserInteractionEnabled = true
        
        exchangeVC?.sendingCryptoValueTF.textColor = .black
        exchangeVC?.receiveCryptoValueTF.textColor = .black
        
        exchangeVC?.sendToReceiveRelation.isHidden = false
        exchangeVC?.summaryView.isHidden = false
        
        unlockSlideButton()
    }
    
    func setGradientToSlide() {
        slideGradient = exchangeVC?.slideColorView.applyGradient(withColours: [UIColor(ciColor: CIColor(red: 0/255, green: 178/255, blue: 255/255)),
                                                                               UIColor(ciColor: CIColor(red: 0/255, green: 122/255, blue: 255/255))],
                                                                 gradientOrientation: .horizontal)
    }
    
    func lockSlideButton() {
        slideGradient?.removeFromSuperlayer()
        exchangeVC?.slideView.isUserInteractionEnabled = false
    }
    
    func unlockSlideButton() {
        setGradientToSlide()
        exchangeVC?.slideView.isUserInteractionEnabled = true
    }
    
    //text field section
    
    func checkIsFiatTf(textField: UITextField) -> Bool {
        if textField == exchangeVC?.sendingFiatValueTF || textField == exchangeVC?.receiveFiatValueTF {
            return true
        } else {
            return false
        }
    }
    
    func maxSymblosAfterDelimiter(textField: UITextField) -> Int {
        if checkIsFiatTf(textField: textField) {
            return 2
        } else {
            return 8
        }
    }
    
    func checkNumberOfSymbolsAfterDelimeter(textField: UITextField) -> Bool {
        let delimeter = textField.text!.contains(",") ? "," : "."
        let strAfterDot: [String?] = textField.text!.components(separatedBy: delimeter)
        if checkIsFiatTf(textField: textField) {
            return strAfterDot[1]!.count == 2 ? false : true
        } else {
            return strAfterDot[1]!.count == 8 ? false : true
        }
    }
    
//    func maxAllowedToSpend(stringWithEnteredNumber: String) -> Bool {
//        BigInt(stringWithEnteredNumber, <#T##blockchain: Blockchain##Blockchain#>)
//
//        walletFromSending?.availableAmount
//    }
    
        //Delete section
    func deleteEnteredIn(textField: UITextField) -> Bool {
//        makeSendFiat(enteredNumber: "")
        if checkIsFiatTf(textField: textField) {
            if textField.text == "$ " {             // "$ " default value in fiat tf
                return false
            } else if textField.text == "$ 0," || textField.text == "$ 0." {
                textField.text = "$ "
                return false
            }
        }
        
        if textField.text == "0," || textField.text == "0." {
            textField.text?.removeAll()
            
            return false
        }
        
        return true
    }
        // -------- done -------- //
        // Delimeter Section
    func delimiterEnteredIn(textField: UITextField) -> Bool {
        // if text contains delimeter than return false
        if textField.text!.contains(",") || textField.text!.contains(".") {
            return false
        }
        
        //if text is empty return 0.
        if checkIsFiatTf(textField: textField) && textField.text == "$ " {
            textField.text = "$ 0."
            
            return false
        } else if textField.text!.isEmpty {
            textField.text = "0."
            
            return false
        }
        
        return true
    }
        // -------- done -------- //
        //Value section
    func numberEnteredIn(textField: UITextField) -> Bool {
//        makeSendFiat(enteredNumber: enteredNumber)
        var textInTfWithOneMoreSymbol = textField.text!.replacingOccurrences(of: "$ ", with: "") + " "  //remove "$ " for fiat TF
        textInTfWithOneMoreSymbol = textInTfWithOneMoreSymbol.replacingOccurrences(of: ".", with: "")
        if textInTfWithOneMoreSymbol.count > 12 {
            return false
        }
        if textField.text!.contains(",") || textField.text!.contains(".") {
            return checkNumberOfSymbolsAfterDelimeter(textField: textField)
        }
        
        return true
    }
        // -------- done -------- //
    
    
    
    func makeSendFiatTfValue() {
        let str = exchangeVC!.sendingCryptoValueTF.text!
        exchangeVC!.sendingFiatValueTF.text = "$ " + str.fiatValueString(for: walletFromSending!.blockchainType)
        
        //added
        let anotherAmount = str.convertCryptoAmountStringToMinimalUnits(for: sendObject) * marketInfo.rate
        let anotherAmountString = anotherAmount.cryptoValueString(for: sendObject)
        exchangeVC!.receiveCryptoValueTF.text! = anotherAmountString
        exchangeVC!.receiveFiatValueTF.text = "$ " + anotherAmountString.fiatValueString(for: walletToReceive!.blockchainType)
    }
    
    func makeSendCryptoTfValue() {
        let valueFromTF = exchangeVC!.sendingFiatValueTF.text!.replacingOccurrences(of: "$ ", with: "")
        let sumInFiat = walletFromSending!.blockchain.multiplierToMinimalUnits * Double(valueFromTF.stringWithDot)
        let endCryptoString = sumInFiat / walletFromSending?.exchangeCourse
        if valueFromTF.isEmpty {
            exchangeVC!.sendingCryptoValueTF.text = "0.0"
        } else {
            exchangeVC!.sendingCryptoValueTF.text = endCryptoString.cryptoValueString(for: walletFromSending!.blockchain)
        }
        
        //added
        let str = exchangeVC!.sendingCryptoValueTF.text!
        
        let anotherAmount = str.convertCryptoAmountStringToMinimalUnits(for: walletFromSending!.blockchain) * marketInfo.rate
        let anotherAmountString = anotherAmount.cryptoValueString(for: walletFromSending!.blockchain)
        exchangeVC!.receiveCryptoValueTF.text! = anotherAmountString
        exchangeVC!.receiveFiatValueTF.text = "$ " + anotherAmountString.fiatValueString(for: walletToReceive!.blockchainType)
    }
    
    func makeReceiveFiatString() {
        let str = exchangeVC!.receiveCryptoValueTF.text!
        exchangeVC!.receiveFiatValueTF.text = "$ " + str.fiatValueString(for: walletToReceive!.blockchainType)
        
        //added
        let anotherAmount = str.convertCryptoAmountStringToMinimalUnits(for: receiveObject) * (1 / marketInfo.rate)
        let anotherAmountString = anotherAmount.cryptoValueString(for: receiveObject)
        exchangeVC!.sendingCryptoValueTF.text! = anotherAmountString
        exchangeVC!.sendingFiatValueTF.text = "$ " + anotherAmountString.fiatValueString(for: walletFromSending!.blockchainType)
    }
    
    func makeReceiveCryptoTfValue() {
        let valueFromTF = exchangeVC!.receiveFiatValueTF.text!.replacingOccurrences(of: "$ ", with: "")
        let sumInFiat = walletToReceive!.blockchain.multiplierToMinimalUnits * Double(valueFromTF.stringWithDot)
        let endCryptoString = sumInFiat / walletToReceive!.exchangeCourse
        if valueFromTF.isEmpty {
            exchangeVC!.receiveCryptoValueTF.text = "0.0"
        } else {
            exchangeVC!.receiveCryptoValueTF.text = endCryptoString.cryptoValueString(for: walletToReceive!.blockchain)
        }
        
        //added
        let str = exchangeVC!.receiveCryptoValueTF.text!
        
        let anotherAmount = str.convertCryptoAmountStringToMinimalUnits(for: walletToReceive!.blockchain) * (1 / marketInfo.rate)
        let anotherAmountString = anotherAmount.cryptoValueString(for: walletToReceive!.blockchain)
        exchangeVC!.sendingCryptoValueTF.text! = anotherAmountString
        exchangeVC!.sendingFiatValueTF.text = "$ " + anotherAmountString.fiatValueString(for: walletFromSending!.blockchainType)
    }
    
    func sendWallet(wallet: UserWalletRLM) {
        walletToReceive = wallet
    }
    
    @objc func getMarketInfo() {
        let fromBlockchain = walletFromSending!.assetShortName
        let toBlockchain = walletToReceive!.assetShortName
        
        exchangeVC?.loader.show(customTitle: localize(string: Constants.loadingString))
        DataManager.shared.apiManager.exchangeAmount(fromBlockchain: fromBlockchain,
                                                     toBlockchain: toBlockchain,
                                                     amount: "1") { [unowned self] in
                                                        self.exchangeVC?.loader.hide()
                                                        switch $0 {
                                                        case .success(let info):
                                                            self.exchangeAmountProcessing(info: info)
                                                        case .failure(_):
                                                            self.lockSlideButton()
                                                            self.exchangeVC?.presentAlert(with: self.localize(string: Constants.cannotRetrieveExchangeRateString))
                                                        }
        }
        
        //quickex
//        let date = Date()
//        DataManager.shared.marketInfo(fromBlockchain: walletFromSending!.blockchain,
//                                      toBlockchain: walletToReceive!.blockchain) {
//                                        switch $0 {
//                                        case .success(let info):
//                                            print(info)
//                                            print(Date().timeIntervalSince(date))
//                                            self.marketInfo.updateMarketInfo(dict: info)
//                                            self.exchangeVC!.sendingCryptoValueChanged(self)
//                                        case .failure(let error):
//                                            print(error)
//                                        }
//        }
    }
    
    func exchangeAmountProcessing(info: NSDictionary) {
        if let amount = info["amount"] as? String, amount.isEmpty == false {
            marketInfo.rate = Double(amount)!
            makeBlockchainRelation()
        } else {
            lockSlideButton()
            exchangeVC?.presentAlert(with: self.localize(string: Constants.assetsNotConvertibleString))
        }
    }
    
    func getFeeRate(_ blockchainType: BlockchainType, address: String?, completion: @escaping (Result<Bool, String>) -> ()) {
        DataManager.shared.getFeeRate(currencyID: blockchainType.blockchain.rawValue,
                                      networkID: UInt32(blockchainType.net_type),
                                      ethAddress: address,
                                      completion: { (dict, error) in
                                        print(dict)
                                        if dict != nil, let feeRates = dict!["speeds"] as? NSDictionary, let fastFeeRate = feeRates["Fast"] as? UInt64 {
                                            if let gasLimitForMS = dict!["gaslimit"] as? String {
                                                self.feeRate = "\(fastFeeRate)"
                                                self.gasLimit = gasLimitForMS
                                            } else {
                                                self.feeRate = "\(fastFeeRate)"
                                                self.gasLimit = "21000"
                                            }
                                            
                                            completion(Result.success(true))
                                        } else {
                                            if error == nil {
                                                completion(Result.failure(self.localize(string: Constants.errorString)))
                                            } else {
                                                completion(Result.failure(error!.localizedDescription))
                                            }
                                        }
        })
    }
    
    func creatreExchangeRequest() {
        let fromTicker = walletFromSending!.assetShortName
        let toTicker = walletToReceive!.assetShortName
        let amountString = exchangeVC!.sendingCryptoValueTF.text!.replacingOccurrences(of: ",", with: ".")
        
        exchangeVC?.loader.showAndLock(customTitle: localize(string: Constants.loadingString))
        DataManager.shared.apiManager.exchangeAmount(fromBlockchain: fromTicker,
                                                     toBlockchain: toTicker,
                                                     amount: amountString) { [unowned self] in
                                                        switch $0 {
                                                        case .success(let info):
                                                            self.retrieveChangellyTX()
                                                        case .failure(let error):
                                                            self.exchangeVC?.loader.hideAndUnlock()
                                                            self.exchangeVC?.presentAlert(with: error)
                                                        }
        }
        
        //quickex

//        let pairString = DataManager.shared.currencyPairString(fromBlockchain: walletFromSending!.blockchain, toBlockchain: walletToReceive!.blockchain)
//
//        DataManager.shared.exchange(amountString: amountString,
//                                    withdrawalAddress: walletToReceive!.address,
//                                    pairString: pairString,
//                                    returnAddress: walletFromSending!.address) { [unowned self] in
//                                        switch $0 {
//                                        case .success(let info):
//                                            print(info)
//                                            self.sendTX(info: info)
//                                        case .failure(let error):
//                                            print(error)
//                                        }
//        }
    }
    
    func retrieveChangellyTX() {
        let fromTicker = walletFromSending!.assetShortName
        let toTicker = walletToReceive!.assetShortName
        let amountString = exchangeVC!.sendingCryptoValueTF.text!.replacingOccurrences(of: ",", with: ".")
        let toAddress = walletToReceive!.assetAddress
        DataManager.shared.apiManager.createExchangeTransaction(fromBlockchain: fromTicker,
                                                                toBlockchain: toTicker,
                                                                amount: amountString,
                                                                receiveAddress: toAddress) { [unowned self] in
                                                                    //check zero
                                                                    switch $0 {
                                                                    case .success(let info):
                                                                        self.checkExchangeInfoAndSend(amountString: amountString, info: info)
                                                                    case .failure(let error):
                                                                        self.exchangeVC?.loader.hideAndUnlock()
                                                                        self.exchangeVC?.presentAlert(with: error)
                                                                    }
        }
    }
    
    func checkExchangeInfoAndSend(amountString: String, info: NSDictionary) {
        guard let payingAddress = info["payinAddress"] as? String, payingAddress.isEmpty == false else {
            exchangeVC?.loader.hideAndUnlock()
            exchangeVC!.presentAlert(with: localize(string: Constants.unableToExchangeString))
            
            return
        }
        
        let dict = ["deposit" : payingAddress,
                    "depositAmount" : Double(amountString)!
            ] as NSDictionary
        self.sendTX(info: dict)
    }
    
    func sendTX(info: NSDictionary) {
        let depositAddress = info["deposit"] as! String
        
        getFeeRate(walletFromSending!.assetBlockchainType, address: depositAddress) {
            switch $0 {
            case .success(_):
                DispatchQueue.main.async {
                    self.createAndSendTX(info: info)
                }
            case .failure(let error):
                self.exchangeVC?.loader.hideAndUnlock()
                self.exchangeVC?.presentAlert(with: error)
                print(error)
            }
        }
    }
    
    func createAndSendTX(info: NSDictionary) {
        let depositAmountString = (info["depositAmount"] as! NSNumber).stringValue.convertCryptoAmountStringToMinimalUnits(for: walletFromSending?.blockchain).stringValue
        let depositAddress = info["deposit"] as! String
        
        var trData = (isTransactionCorrect: false, message: "Error")
        var binaryData = DataManager.shared.realmManager.account!.binaryDataString.createBinaryData()!
        let addressData = DataManager.shared.createAddress(blockchainType:walletFromSending!.assetBlockchainType,
                                                           walletID:      walletFromSending!.assetWallet.walletID.uint32Value,
                                                           addressID:     walletFromSending!.assetWallet.changeAddressIndex,
                                                           binaryData:    &binaryData)
        var correctedAmount = depositAmountString
        
        switch walletFromSending!.assetBlockchain {
        case BLOCKCHAIN_BITCOIN:
            //BTC: imported not supported
            //FIXME:
            let data = DataManager.shared.createTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                            sendAddress: depositAddress,
                                                            sendAmountString: BigInt(depositAmountString).cryptoValueString(for: walletFromSending!.assetBlockchain),
                                                            feePerByteAmount: feeRate,
                                                            isDonationExists: false,
                                                            donationAmount: "",
                                                            isPayCommission: !isSendMax,
                                                            wallet: walletFromSending!.assetWallet,
                                                            binaryData: &binaryData,
                                                            inputs: walletFromSending!.assetWallet.addresses)
            
            trData = (isTransactionCorrect: data.1 >= 0, message: data.0)
        case BLOCKCHAIN_ETHEREUM:
            if isSendMax && walletFromSending!.blockchain == BLOCKCHAIN_ETHEREUM {
                correctedAmount = (BigInt(depositAmountString) - BigInt(feeRate) * BigInt(gasLimit)).stringValue
            }
            
            trData = DataManager.shared.createETHTransaction(wallet: walletFromSending!.assetWallet,
                                                             sendAmountString: correctedAmount,
                                                             destinationAddress: depositAddress,
                                                             gasPriceAmountString: feeRate,
                                                             gasLimitAmountString: gasLimit)
        default:
            exchangeVC?.loader.hideAndUnlock()
            exchangeVC?.presentAlert(with: "\(walletFromSending!.assetBlockchain.fullName): \(localize(string: Constants.notImplementedYet))")
        }
        
        if trData.isTransactionCorrect == false {
            exchangeVC?.loader.hideAndUnlock()
            exchangeVC?.presentAlert(with: "\(localize(string: Constants.transactionErrorString)): \(trData.message)")
            
            return
        }
        
        let addressIndex = walletFromSending!.assetWallet.blockchain == BLOCKCHAIN_ETHEREUM ? 0 : walletFromSending!.assetWallet.addresses.count
        
        let newAddressParams = [
            "walletindex"   : walletFromSending!.walletID.intValue,
            "address"       : addressData!["address"] as! String,
            "addressindex"  : addressIndex,
            "transaction"   : trData.message,
            "ishd"          : walletFromSending!.shouldCreateNewAddressAfterTransaction
            ] as [String : Any]
        
        let params = [
            "currencyid": walletFromSending!.chain,
            /*"JWT"       : jwtToken,*/
            "networkid" : walletFromSending!.chainType,
            "payload"   : newAddressParams
            ] as [String : Any]
        
        DataManager.shared.sendHDTransaction(transactionParameters: params) { [unowned self] (dict, error) in
            self.exchangeVC?.loader.hideAndUnlock()
            
            if error != nil {
                if let info = (error as NSError?)?.userInfo["message"] as? String {
                    self.exchangeVC?.presentAlert(with: info)
                } else {
                    self.exchangeVC?.presentAlert(with: error?.localizedDescription)
                }
            } else {
                
                
                
                let value = BigInt(depositAmountString).cryptoValueStringWithTicker(for: self.walletFromSending!.assetBlockchain)
                self.presentSuccesScreen(value , depositAddress)
            }
        }
    }
    
    func sendAnalytics(amountString: String) {
        guard let pairString = DataManager.shared.currencyPairString(fromAsset: walletFromSending?.assetObject, toAsset: walletToReceive?.assetObject) else {
            return
        }
        
        exchangeSuccess(pairString: pairString, amount: BigInt(amountString).cryptoValueString(for: walletFromSending!.assetObject))
    }
    
    func presentSuccesScreen(_ amount: String, _ address: String) {
        let sendOKVC = viewControllerFrom("Send", "SuccessSendVC") as! SendingAnimationViewController
        sendOKVC.presenter.fundsReceived(amount, address, fromVCType: .exchange)
        sendOKVC.chainId = Int(walletFromSending!.assetWallet.blockchain.rawValue)
        
        exchangeVC?.navigationController?.pushViewController(sendOKVC, animated: true)
    }

    //changelly
    func checkMinAmountExchange(from: String, to: String) {
        if from.isEmpty || to.isEmpty {
            return
        }
        
        DataManager.shared.apiManager.getMinExchangeAmount(fromBlockchain: from, toBlockchain: to) { (answerDict, err) in
            if err != nil || answerDict == nil {
                //error
            } else {
                self.minimalValueString = answerDict!["amount"] as! String
            }
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Wallets"
    }
}
