//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

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

class ExchangePresenter: NSObject, SendWalletProtocol {
    var exchangeMarket = ExchangeMarket.changelly
    var marketInfo = MarketInfo()
    
    var exchangeVC: ExchangeViewController?
    var supportedTokens: Array<TokenRLM>?
    var walletFromSending: UserWalletRLM? {
        didSet {
            updateUI()
            
            if walletFromSending == nil {
                return
            }
            
            feeRate = walletFromSending!.blockchain.defaultfeeRate
            gasLimit = walletFromSending!.blockchain.defaultGasLimit
        }
    }
    
    var feeRate = "1"
    var gasLimit = "\(1_000_000_000)"

    var walletToReceive: UserWalletRLM? {
        didSet {
            getMarketInfo()
            updateReceiveSection()
            enableUI()
        }
    }
    
    func updateUI() {
        exchangeVC?.sendingImg.image = UIImage(named: walletFromSending!.blockchainType.iconString)
        exchangeVC?.sendingMaxBtn.setTitle("MAX \(walletFromSending!.availableAmountString)", for: .normal)
        exchangeVC?.sendingCryptoName.text = walletFromSending?.blockchainType.shortName
        setEndValueToSend()
//        setEndValueToSend()
    }
    
    func setEndValueToSend() {
        exchangeVC?.summarySendingWalletNameLbl.text = walletFromSending?.name
        exchangeVC?.summarySendingCryptoValueLbl.text = exchangeVC!.sendingCryptoValueTF.text
        exchangeVC?.summarySendingCryptoNameLbl.text = walletFromSending?.blockchainType.shortName
        exchangeVC?.summarySendingImg.image = UIImage(named: walletFromSending!.blockchainType.iconString)
        exchangeVC?.summarySendingFiatLbl.text = exchangeVC!.sendingFiatValueTF.text!
    }
    
    
    func updateReceiveSection() {
        exchangeVC?.receiveCryptoImg.image = UIImage(named: walletToReceive!.blockchainType.iconString)
        exchangeVC?.receiveCryptoNameLbl.text = walletToReceive!.blockchainType.shortName
        makeBlockchainRelation()
        setEndValueToReceive()
    }
    
    func setEndValueToReceive() {
        exchangeVC?.summaryReceiveWalletNameLbl.text = walletToReceive!.name
        exchangeVC?.summaryReceiveImg.image = UIImage(named: walletToReceive!.blockchainType.iconString)
        exchangeVC?.summaryReceiveCryptoValueLbl.text = exchangeVC?.receiveCryptoValueTF.text
        exchangeVC?.summaryReceiveCryptoNameLbl.text = walletToReceive!.blockchainType.shortName
        exchangeVC?.summaryReceiveFiatLbl.text = exchangeVC?.receiveFiatValueTF.text
    }
    
    func makeBlockchainRelation() {
        let relationString = String(marketInfo.rate).showString(8) //String(walletFromSending!.exchangeCourse / walletToReceive!.exchangeCourse).showString(8)
        exchangeVC?.sendToReceiveRelation.text = "1 " + walletFromSending!.blockchainType.shortName + "= " + relationString + " " + walletToReceive!.blockchainType.shortName
    }
    
    func enableUI() {
        exchangeVC?.receiveFiatValueTF.isUserInteractionEnabled = true
        exchangeVC?.receiveCryptoValueTF.isUserInteractionEnabled = true
        exchangeVC?.sendingFiatValueTF.isUserInteractionEnabled = true
        exchangeVC?.sendingCryptoValueTF.isUserInteractionEnabled = true
        exchangeVC?.receiveFiatValueTF.textColor = .black
        exchangeVC?.receiveCryptoValueTF.textColor = .black
        exchangeVC?.sendingFiatValueTF.textColor = .black
        exchangeVC?.sendingCryptoValueTF.textColor = .black
        
        exchangeVC?.sendToReceiveRelation.isHidden = false
        exchangeVC?.summaryView.isHidden = false
        
        exchangeVC?.slideView.isUserInteractionEnabled = true
        setGradientToSlide()
    }
    
    func setGradientToSlide() {
        exchangeVC?.slideColorView.applyGradient(withColours: [UIColor(ciColor: CIColor(red: 0/255, green: 178/255, blue: 255/255)),
                                                   UIColor(ciColor: CIColor(red: 0/255, green: 122/255, blue: 255/255))],
                                     gradientOrientation: .horizontal)
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
        let anotherAmount = str.convertCryptoAmountStringToMinimalUnits(for: walletFromSending!.blockchain) * marketInfo.rate
        let anotherAmountString = anotherAmount.cryptoValueString(for: walletFromSending!.blockchain)
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
        let anotherAmount = str.convertCryptoAmountStringToMinimalUnits(for: walletToReceive!.blockchain) * (1 / marketInfo.rate)
        let anotherAmountString = anotherAmount.cryptoValueString(for: walletToReceive!.blockchainType.blockchain)
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
    
    func checkForExistingWallet() {
        let blockchainToReceive = walletFromSending?.blockchain == BLOCKCHAIN_ETHEREUM ? BlockchainType(blockchain: BLOCKCHAIN_BITCOIN, net_type: 0) : BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: 1)
        RealmManager.shared.getAllWalletsFor(blockchainType: blockchainToReceive) { (wallets, error) in
            let storyboard = UIStoryboard(name: "Receive", bundle: nil)
            let walletsVC = storyboard.instantiateViewController(withIdentifier: "ReceiveStart") as! ReceiveStartViewController
            walletsVC.presenter.walletsArr = Array(wallets!)
            walletsVC.presenter.isNeedToPop = true
            walletsVC.whereFrom = self.exchangeVC
            walletsVC.sendWalletDelegate = self//self.mainVC?.sendWalletDelegate
            walletsVC.presenter.displayedBlockchainOnly = blockchainToReceive
            self.exchangeVC!.navigationController?.pushViewController(walletsVC, animated: true)
        }
    }
    
    @objc func getMarketInfo() {
        let fromBlockchain = walletFromSending!.blockchain.shortName
        let toBlockchain = walletToReceive!.blockchain.shortName
        DataManager.shared.apiManager.exchangeAmount(fromBlockchain: fromBlockchain,
                                                     toBlockchain: toBlockchain,
                                                     amount: "1") { [unowned self] in
                                                        switch $0 {
                                                        case .success(let info):
                                                            if let amount = info["amount"] as? String {
                                                                self.marketInfo.rate = Double(amount)!
                                                                self.makeBlockchainRelation()
                                                            }
                                                        case .failure(let error):
                                                            print(error)
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
    
    func getFeeRate(_ blockchainType: BlockchainType, address: String?, completion: @escaping (Result<Bool, String>) -> ()) {
        DataManager.shared.getFeeRate(currencyID: blockchainType.blockchain.rawValue,
                                      networkID: UInt32(blockchainType.net_type),
                                      ethAddress: address,
                                      completion: { (dict, error) in
                                        print(dict)
                                        if let feeRates = dict!["speeds"] as? NSDictionary, let fastFeeRate = feeRates["Fast"] as? UInt64 {
                                            if let gasLimitForMS = dict!["gaslimit"] as? String {
                                                self.feeRate = "\(fastFeeRate)"
                                                self.gasLimit = gasLimitForMS
                                            } else {
                                                self.feeRate = "\(fastFeeRate)"
                                            }
                                            
                                            completion(Result.success(true))
                                        } else {
                                            if error == nil {
                                                completion(Result.failure("Error"))
                                            } else {
                                                completion(Result.failure(error!.localizedDescription))
                                            }
                                        }
        })
    }
    
    func creatreExchangeRequest() {
        let fromTicker = walletFromSending!.blockchain.shortName
        let toTicker = walletToReceive!.blockchain.shortName
        let amountString = exchangeVC!.sendingCryptoValueTF.text!.replacingOccurrences(of: ",", with: ".")
        
        
        DataManager.shared.apiManager.exchangeAmount(fromBlockchain: fromTicker,
                                                     toBlockchain: toTicker,
                                                     amount: amountString) { [unowned self] in
                                                        switch $0 {
                                                        case .success(let info):
                                                            self.retrieveChangellyTX()
                                                        case .failure(let error):
                                                            print(error)
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
        let fromTicker = walletFromSending!.blockchain.shortName
        let toTicker = walletToReceive!.blockchain.shortName
        let amountString = exchangeVC!.sendingCryptoValueTF.text!.replacingOccurrences(of: ",", with: ".")
        let toAddress = walletToReceive!.address
        DataManager.shared.apiManager.createExchangeTransaction(fromBlockchain: fromTicker,
                                                                toBlockchain: toTicker,
                                                                amount: amountString,
                                                                receiveAddress: toAddress) { [unowned self] in
                                                                    //check zero
                                                                    switch $0 {
                                                                    case .success(let info):
                                                                        let dict = ["deposit" : info["payinAddress"] as! String,
                                                                                    "depositAmount" : Double(amountString)!
                                                                                    ] as NSDictionary
                                                                        self.sendTX(info: dict)
                                                                    case .failure(let error):
                                                                        print(error)
                                                                    }
                                                                    
                                                                    print($0)
        }
    }
    
    func sendTX(info: NSDictionary) {
        let depositAddress = info["deposit"] as! String
        
        getFeeRate(walletFromSending!.blockchainType, address: depositAddress) {
            switch $0 {
            case .success(_):
                DispatchQueue.main.async {
                    self.createAndSendTX(info: info)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func createAndSendTX(info: NSDictionary) {
        let depositAmountString = (info["depositAmount"] as! NSNumber).stringValue.convertCryptoAmountStringToMinimalUnits(for: walletFromSending?.blockchain).stringValue
        let depositAddress = info["deposit"] as! String
        
        let trData = DataManager.shared.createETHTransaction(wallet: walletFromSending!,
                                                             sendAmountString: depositAmountString,
                                                             destinationAddress: depositAddress,
                                                             gasPriceAmountString: feeRate,
                                                             gasLimitAmountString: gasLimit)
        
        let newAddressParams = [
            "walletindex"   : walletFromSending!.walletID.intValue,
            "address"       : walletFromSending!.address,
            "addressindex"  : 0,
            "transaction"   : trData.message,
            "ishd"          : walletFromSending!.shouldCreateNewAddressAfterTransaction
            ] as [String : Any]
        
        let params = [
            "currencyid": walletFromSending!.chain,
            /*"JWT"       : jwtToken,*/
            "networkid" : walletFromSending!.chainType,
            "payload"   : newAddressParams
            ] as [String : Any]
        
        DataManager.shared.sendHDTransaction(transactionParameters: params) { (dict, error) in
            print(dict)
        }
    }

    //changelly
    func checkMinAmountExchange(from: Blockchain?, to: Blockchain?) {
        if from == nil && to == nil {
            return
        }
        
        DataManager.shared.apiManager.getMinExchangeAmount(fromBlockchain: from!.shortName, toBlockchain: to!.shortName) { (answerDict, err) in
            if err != nil || answerDict == nil {
                //error
            }
            
            
        }
    }
}
