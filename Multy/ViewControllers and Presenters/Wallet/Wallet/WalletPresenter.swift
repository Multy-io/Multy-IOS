//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

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
        if indexPath.row < transactionDataSource.count && isTherePendingMoney(for: indexPath) {
            return 135
        } else {
            return 70
        }
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
        DataManager.shared.getTransactionHistory(currencyID: self.wallet!.chain, networkID: self.wallet!.chainType, walletID: self.wallet!.walletID) { [unowned self] (histList, err) in
            self.walletVC?.spiner.stopAnimating()
            self.walletVC?.isCanUpdate = true
            if err == nil && histList != nil {
                self.transactionDataSource = histList!.sorted(by: {
                    let firstDate = $0.mempoolTime.timeIntervalSince1970 == 0 ? $0.blockTime : $0.mempoolTime
                    let secondDate = $1.mempoolTime.timeIntervalSince1970 == 0 ? $1.blockTime : $1.mempoolTime
                    
                    return firstDate > secondDate
                })
                self.isSocketInitiateUpdating = false
                
                self.updateHeader()
            }
        }
    }
}
