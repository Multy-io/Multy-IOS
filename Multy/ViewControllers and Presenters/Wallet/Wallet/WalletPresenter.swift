//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
//import MultyCoreLibrary

enum WalletRepresentingMode {
    case allInfo
    case tokenInfo
    case txInfo
}

class WalletPresenter: NSObject {

    var walletVC: WalletViewController?
    
    var tokenHolderWallet: UserWalletRLM?
    var wallet : UserWalletRLM? {
        didSet {
            walletVC?.titleLbl.text = wallet?.name
//            if wallet?.importedPrivateKey.isEmpty == false {
//                importedPrivateKey = wallet!.importedPrivateKey
//                importedPublicKey = wallet!.importedPublicKey
//            }
            prepareAssetsData(array: wallet!.ethWallet?.erc20Tokens)
            updateUI()
            walletVC?.setupUI()
        }
        
        willSet {
            if newValue!.importedPublicKey.isEmpty && wallet?.importedPublicKey.isEmpty == false {
                newValue?.importedPublicKey = wallet?.importedPublicKey ?? ""
                newValue?.importedPrivateKey = wallet?.importedPrivateKey ?? ""
            }
        }
    }
    
//    var importedPublicKey: String?
//    var importedPrivateKey: String?
    
    var account : AccountRLM?
    
    var fiatSymbol: String = "$"
    var assetsDataSource = [WalletTokenRLM]() {
        didSet {
            walletVC?.assetsTable.reloadData()
        }
    }
    
    var transactionDataSource = [HistoryRLM]() {
        didSet {
            if transactionDataSource.isEmpty == false {
                walletVC?.hideEmptyLbls()
            }
            if oldValue != transactionDataSource {
                self.walletVC!.transactionsTable.reloadData()
            }
        }
    }
    
    var isTransactionTableActive: Bool {
        get {
            return walletVC!.assetsTable.frame.origin.x < 0
        }
    }
    
    var isSocketInitiateUpdating = false
    
    var walletRepresentingMode = WalletRepresentingMode.allInfo
    
    var ethToken: WalletTokenRLM {
        get {
            let token = WalletTokenRLM()
            
            token.name = "Ethereum"
            token.ticker = "ETH"
            token.address = "ethereum"
            token.balance = wallet!.ethWallet!.balance
            
            return token
        }
    }
    
    func prepareAssetsData(array: List<WalletTokenRLM>?) {
        if walletRepresentingMode != .allInfo || wallet!.blockchain != BLOCKCHAIN_ETHEREUM {
            return
        }
        
        let array = Array(array ?? List<WalletTokenRLM>())
        assetsDataSource = array.sorted(by: { return $0.name < $1.name })
        
        if assetsDataSource.count > 0 {
            assetsDataSource = [ethToken] + assetsDataSource
        }
    }
    
    func updateUI() {
        if walletVC == nil {
            return
        }
    
        updateHeader()
    }
    
    func registerCells() {
        let transactionCell = UINib.init(nibName: "TransactionWalletCell", bundle: nil)
        walletVC!.transactionsTable.register(transactionCell, forCellReuseIdentifier: "TransactionWalletCellID")
        
        let transactionPendingCell = UINib.init(nibName: "TransactionPendingCell", bundle: nil)
        walletVC!.transactionsTable.register(transactionPendingCell, forCellReuseIdentifier: "TransactionPendingCellID")
        
        let multiSigPendingCell = UINib.init(nibName: "MultiSigPendingTableViewCell", bundle: nil)
        walletVC!.transactionsTable.register(multiSigPendingCell, forCellReuseIdentifier: "multiSigPendingCell")
        
        let tokenCell = UINib.init(nibName: "TokenTableViewCell", bundle: nil)
        walletVC!.assetsTable.register(tokenCell, forCellReuseIdentifier: "tokenCell")
    }
    
    func updateHeader() {
        walletVC!.showHidePendingSection(true)
        
        walletVC!.amountCryptoLbl.text = wallet!.availableAmountString
        
        switch walletRepresentingMode {
        case .allInfo, .txInfo:
            walletVC!.nameCryptoLbl.text = wallet!.blockchain.shortName
            walletVC!.fiatAmountLbl.text = fiatSymbol + wallet!.availableAmountInFiatString
            walletVC!.fiatAmountLbl.enableView()
        case .tokenInfo:
            walletVC!.nameCryptoLbl.text = wallet!.cryptoName
            walletVC!.fiatAmountLbl.disableView()
        }
        
        walletVC!.titleLbl.text = wallet!.name
        
        if wallet!.isThereBlockedAmount {
            walletVC!.pendingAmountCryptoLbl.text = wallet!.sumInCryptoString
            walletVC!.pendingNameCryptoLbl.text = wallet!.blockchain.shortName
            walletVC!.pendingAmountFiatLbl.text = fiatSymbol + wallet!.sumInFiatString
        }
        
        walletVC!.addressLbl.text = wallet!.address
    }
    
    func isTherePendingMoney(for indexPath: IndexPath) -> Bool {
        return transactionDataSource[indexPath.row].isPending()
    }
    
    func makeHeightForTableCells(indexPath: IndexPath) -> CGFloat {
        switch wallet?.isMultiSig {
        case true:
            if indexPath.row < transactionDataSource.count && transactionDataSource[indexPath.row].multisig != nil {   //46
//                if wallet!.isRejected(tx: transactionDataSource[indexPath.row]) {
                if transactionDataSource[indexPath.row].multisig!.confirmed.boolValue {
                    return 126 //64
                } else {
//                    return 172          //fixit: check for lockingmoney
                    return 126 
                }
            } else {
                if indexPath.row < transactionDataSource.count && isTherePendingMoney(for: indexPath) {
                    return 135
                } else {
                    return 64
                }
            }
        case false:
            if indexPath.row < transactionDataSource.count && isTherePendingMoney(for: indexPath) {
                return 135
            } else {
                return 64
            }
        default: return 64 //70
        }
        
//        if indexPath.row < transactionDataSource.count && isTherePendingMoney(for: indexPath) {
//            if transactionDataSource[indexPath.row].isMultisigTx.boolValue {
//                return 172 //fixit: check for lockingmoney
//            } else {
//                return 135
//            }
//        } else {
//            if indexPath.row < transactionDataSource.count && transactionDataSource[indexPath.row].isMultisigTx.boolValue {
//                return 172 //fixit: check for lockingmoney
//            } else {
//                return 70
//            }
//        }
        //FOR MULTISIG TRANSACTIONS
        //            if indexPath.row == 0 {
        //                return 172            //cell with locked and info view
        //            }
        //            return 126                //cell with only locked or only info viewr
    }
    
    func sendTestToken() {
        let info = DataManager.shared.privateInfo(for: tokenHolderWallet!)
        if info == nil { return }

        var txInfo = Dictionary<String, Any>()
        var accountDict = Dictionary<String, Any>()
        var builderDict = Dictionary<String, Any>()
        var payloadDict = Dictionary<String, Any>()
        var txDict = Dictionary<String, Any>()
        var feeDict = Dictionary<String, Any>()
        
        txInfo["blockchain"] = wallet!.blockchain.fullName
        txInfo["net_type"] = wallet!.blockchainType.net_type
        
        //account
        accountDict["type"] = ACCOUNT_TYPE_DEFAULT.rawValue
        accountDict["private_key"] = info!["privateKey"] as! String
        txInfo["account"] = accountDict
        
        //builder
        builderDict["type"] = "erc20"
        builderDict["action"] = "transfer"
        //payload
        payloadDict["balance_eth"] = tokenHolderWallet!.availableBalance.stringValue
        payloadDict["contract_address"] = wallet!.address
        payloadDict["balance_token"] = wallet!.ethWallet!.balance
        payloadDict["transfer_amount_token"] = "1"
        payloadDict["destination_address"] = "0x1430dde34403100a3e2deb515d65dcb6afe889d1"
        builderDict["payload"] = payloadDict
        txInfo["builder"] = builderDict
        
        //transaction
        txDict["nonce"] = tokenHolderWallet!.ethWallet!.nonce
        feeDict["gas_price"] = "1000000000"
        feeDict["gas_limit"] = "\(3_000_000)"
        txDict["fee"] = feeDict
        txInfo["transaction"] = txDict
        
        let rawTX = DataManager.shared.makeTX(from: txInfo)
        
        switch rawTX {
        case .success(let txString):
            print(rawTX)
            
            let newAddressParams = [
                "walletindex"   : tokenHolderWallet!.walletID.intValue,
                "address"       : tokenHolderWallet!.address,
                "addressindex"  : 0,
                "transaction"   : txString,
                "ishd"          : tokenHolderWallet!.shouldCreateNewAddressAfterTransaction
                ] as [String : Any]
            
            let params = [
                "currencyid": tokenHolderWallet!.chain,
                /*"JWT"       : jwtToken,*/
                "networkid" : tokenHolderWallet!.chainType,
                "payload"   : newAddressParams
                ] as [String : Any]
            
            DataManager.shared.sendHDTransaction(transactionParameters: params) { [unowned self] (dict, error) in
                if dict != nil {
                    print(dict)
                } else {
                    print(error)
                }
            }
        case .failure(let error):
            break
        }
    }
    
    func getHistoryAndWallet() {
        if walletVC?.isCanUpdate == false {
            return
        }
        
        if walletRepresentingMode != .allInfo {
//            sendTestToken()
            
            return
        }
        
        DataManager.shared.getOneWalletVerbose(wallet: wallet!) { [unowned self] (updatedWallet, error) in
            if updatedWallet != nil {
                self.wallet = updatedWallet
                self.prepareAssetsData(array: updatedWallet?.ethWallet?.erc20Tokens)
            }
            
            self.getHistory()
        }
    }
    
    func getHistory() {
        DataManager.shared.getTransactionHistory(wallet: wallet!) { [unowned self] (historyArray, error) in
            DispatchQueue.main.async { [unowned self] in
                self.updateTable(historyArray: historyArray, error: error)
            }
        }
    }
    
    func updateTable(historyArray: List<HistoryRLM>?, error: Error?) {
        self.walletVC?.spiner.stopAnimating()
        self.walletVC?.isCanUpdate = true
        if error == nil && historyArray != nil {
            self.transactionDataSource = historyArray!.sorted(by: {
                let firstDate = $0.mempoolTime.timeIntervalSince1970 == 0 ? $0.blockTime : $0.mempoolTime
                let secondDate = $1.mempoolTime.timeIntervalSince1970 == 0 ? $1.blockTime : $1.mempoolTime

                return firstDate > secondDate
            })
            
            self.prepareAssetsData(array: self.wallet!.ethWallet?.erc20Tokens)
            
            self.isSocketInitiateUpdating = false
            
            self.updateHeader()
        }
        walletVC!.setupUI()
    }
    
    func canSendMinimumAmount() -> Bool {
        if wallet!.blockchain == BLOCKCHAIN_ETHEREUM && wallet!.ethWallet!.ethBalance < "0.0001".convertCryptoAmountStringToMinimalUnits(in: BLOCKCHAIN_ETHEREUM) {
            let title = walletVC!.localize(string: Constants.sorryString)
            let message = walletVC!.localize(string: Constants.lowAmountString)
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            walletVC!.present(alert, animated: true, completion: nil)
            
            return false
        }
        return true
    }
    
    func checkForInvokationStatus(histObj: HistoryRLM) -> Bool {
        if histObj.multisig != nil && histObj.multisig?.invocationStatus == false {
            return false
        } else {
            return true
        }
    }
    
    func makeWalletFrom(token: WalletTokenRLM) -> UserWalletRLM {
        let tokenWallet = UserWalletRLM()
        
        tokenWallet.address = token.address
        tokenWallet.name = token.name
        tokenWallet.chain = NSNumber(value: token.token?.blockchainType.blockchain.rawValue ?? 0)
        tokenWallet.chainType = wallet!.chainType
        tokenWallet.cryptoName = token.ticker
//        tokenWallet.importedPrivateKey = self.wallet!.importedPrivateKey
//        tokenWallet.importedPublicKey = self.wallet!.importedPublicKey
//        tokenWallet.fiatName = self.wallet!.fiatName
//        tokenWallet.fiatSymbol = self.wallet!.fiatSymbol
        tokenWallet.ethWallet = ETHWallet()
        tokenWallet.ethWallet!.balance = token.balance
        
        return tokenWallet
    }
}
