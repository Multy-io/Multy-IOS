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
            
            if wallet != nil && wallet!.chain.intValue == 60 && wallet!.chainType.intValue == 4 {
                var binData = account!.binaryDataString.createBinaryData()!
                let _ = DataManager.shared.createMultiSigWallet(binaryData: &binData,
                                                                wallet: wallet!,
                                                                sendAddress: wallet!.address,
                                                                creationPriceString: "0",
                                                                gasPriceString: "6000000000",
                                                                gasLimitString: "2029935",
                                                                factoryAddress: "0x116ffa11dd8829524767f561da5d33d3d170e17d",
                                                                owners: "[0x6b4be1fc5fa05c5d959d27155694643b8af72fd8, 0x2b74679d2a190fd679a85ce7767c05605237f030, 0xbc11d8f8d741515d2696e34333a0671adb6aee34]",
                                                                confirmationsCount: UInt32(2))
            }
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
        DataManager.shared.getOneWalletVerbose(walletID: wallet!.walletID, blockchain: BlockchainType.create(wallet: wallet!)) { [unowned self] (wallet, error) in
            if wallet != nil {
                self.wallet = wallet
            }
            
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
}
