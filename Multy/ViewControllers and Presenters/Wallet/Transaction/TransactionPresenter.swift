//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class TransactionPresenter: NSObject {
    var transctionVC: TransactionViewController?
    
    let receiveBackColor = UIColor(red: 95/255, green: 204/255, blue: 125/255, alpha: 1.0)
    let sendBackColor = UIColor(red: 0/255, green: 183/255, blue: 255/255, alpha: 1.0)
    let waitingConfirmationBackColor = UIColor(red: 249/255, green: 250/255, blue: 255/255, alpha: 1.0)
    
    var histObj = HistoryRLM()
    var blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_BITCOIN, net_type: -1)
    var wallet = UserWalletRLM() {
        didSet {
            blockchain = wallet.blockchainType.blockchain
        }
    }
    
    var blockchain: Blockchain?
    var selectedAddress: String?
    var isDonationExist = false
    
    var binaryData : BinaryData?
    var addressData : Dictionary<String, Any>?
    var linkedWallet: UserWalletRLM?
    
    func blockedAmount(for transaction: HistoryRLM) -> UInt64 {
        var sum = UInt64(0)
        
        if transaction.txStatus.intValue == TxStatus.MempoolIncoming.rawValue {
            sum += transaction.txOutAmount.uint64Value
        } else if transaction.txStatus.intValue == TxStatus.MempoolOutcoming.rawValue {
            for tx in transaction.txOutputs {
                sum += tx.amount.uint64Value
            }
        }
        
        return sum
    }
    
    func createPreliminaryData() {
        let core = DataManager.shared.coreLibManager
        DataManager.shared.getAccount { [unowned self] (account, error) in
            if account != nil {
                self.binaryData = account!.binaryDataString.createBinaryData()!
                
                
                
                self.addressData = core.createAddress(blockchainType:   self.wallet.blockchainType,
                                                      walletID:         self.wallet.walletID.uint32Value,
                                                      addressID:        self.wallet.changeAddressIndex,
                                                      binaryData:      &self.binaryData!)
                
                if self.wallet.isMultiSig {
                    DataManager.shared.getWallet(primaryKey: self.wallet.multisigWallet!.linkedWalletID) { [unowned self] in
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
        }
    }
    
    func confirmMultisigTx() {
        transctionVC?.spiner.startAnimating()
        
//        let trData = DataManager.shared.confirmMultiSigTx(binaryData: &<#T##BinaryData#>,
//                                                          wallet: <#T##UserWalletRLM#>,
//                                                          balanceAmountString: <#T##String#>,
//                                                          sendFromAddress: <#T##String#>,
//                                                          nonce: <#T##Int#>,
//                                                          nonceMultiSigTx: <#T##Int#>,
//                                                          gasPriceString: <#T##String#>,
//                                                          gasLimitString: <#T##String#>)
        
        DataManager.shared.confirmMultiSigTx(wallet: wallet, histObj: histObj) {[unowned self] result in
            self.transctionVC?.spiner.stopAnimating()
            switch result {
            case .success( _):
                self.updateTx()
            case .failure(let error):
                print(error)
                self.transctionVC?.presentAlert(with: error)
            }
        }
    }
    
    func declineMultisigTx() {
        transctionVC?.spiner.startAnimating()
        DataManager.shared.declineMultiSigTx(wallet: wallet, histObj: histObj) {[unowned self] result in
            self.transctionVC?.spiner.stopAnimating()
            switch result {
            case .success( _):
                self.updateTx()
            case .failure(let error):
                print(error)
                self.transctionVC?.presentAlert(with: error)
            }
        }
    }
    
    func updateTx() {
        let blockchainType = BlockchainType.create(wallet: wallet)
        DataManager.shared.getOneMultisigWalletVerbose(inviteCode: wallet.multisigWallet!.inviteCode, blockchain: blockchainType) { (wallet, error) in
            // FIXME: invoke updating transaction history and then update UI
        }
    }
}


