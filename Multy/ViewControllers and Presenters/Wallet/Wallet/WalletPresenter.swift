//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
//import MultyCoreLibrary

class WalletPresenter: NSObject {

    var walletVC: WalletViewController?
    var wallet : UserWalletRLM? {
        didSet {
            walletVC?.titleLbl.text = wallet?.name
//            if wallet?.importedPrivateKey.isEmpty == false {
//                importedPrivateKey = wallet!.importedPrivateKey
//                importedPublicKey = wallet!.importedPublicKey
//            }
            updateUI()
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
    var assetsDataSource = [HistoryRLM]() {
        didSet {
            walletVC!.assetsTable.reloadData()
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
        walletVC!.nameCryptoLbl.text = wallet!.blockchain.shortName
        walletVC!.fiatAmountLbl.text = fiatSymbol + wallet!.availableAmountInFiatString
        
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
    
    
    func getHistoryAndWallet() {
        if walletVC?.isCanUpdate == false {
            return
        }
        
        DataManager.shared.getOneWalletVerbose(wallet: wallet!) { [unowned self] (updatedWallet, error) in
            if updatedWallet != nil {
                self.wallet = updatedWallet
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
            self.isSocketInitiateUpdating = false
            
            self.updateHeader()
        }
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
}
