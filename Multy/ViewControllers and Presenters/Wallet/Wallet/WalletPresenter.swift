//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

class WalletPresenter: NSObject {

    var walletVC: WalletViewController?
    var wallet : UserWalletRLM? {
        didSet {
            walletVC?.titleLbl.text = wallet?.name
            updateUI()
        }
    }
    
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
            walletVC!.transactionsTable.reloadData()
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
                if wallet!.isRejected(tx: transactionDataSource[indexPath.row]) {
                    return 126
                } else {
//                    return 172          //fixit: check for lockingmoney
                    return 126 
                }
            } else {
                return 70
            }
        case false:
            if indexPath.row < transactionDataSource.count && isTherePendingMoney(for: indexPath) {
                return 135
            } else {
                return 70
            }
        default: return 70
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
        
        if wallet!.isMultiSig {
            let blockchainType = BlockchainType.create(wallet: wallet!)
            DataManager.shared.getOneMultisigWalletVerbose(inviteCode: wallet!.multisigWallet!.inviteCode,
                                                           blockchain: blockchainType) { [unowned self] (wallet, error) in
                                                            if wallet != nil {
                                                                self.wallet = wallet
                                                            }
                                                            
                                                            self.getHistory()
            }
        } else {
            DataManager.shared.getOneWalletVerbose(walletID: wallet!.walletID, blockchain: BlockchainType.create(wallet: wallet!)) { [unowned self] (wallet, error) in
                if wallet != nil {
                    self.wallet = wallet
                }
                
                self.getHistory()
            }
        }
    }
    
    func getHistory() {
        if wallet!.isMultiSig {
            if wallet!.address.isEmpty {
                self.updateTable(historyArray: List<HistoryRLM>(), error: nil)
                
                return
            }
            
            DataManager.shared.getMultisigTransactionHistory(currencyID: wallet!.chain,
                                                             networkID: wallet!.chainType,
                                                             address: wallet!.address) { [unowned self] (historyArray, error) in
                                                                self.updateTable(historyArray: historyArray, error: error)
            }
        } else {
            DataManager.shared.getTransactionHistory(currencyID: wallet!.chain,
                                                     networkID: wallet!.chainType,
                                                     walletID: self.wallet!.walletID) { [unowned self] (historyArray, error) in
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
}
