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
    
    var isMultisigTxViewed : Bool {
        get {
            var result = false
            if histObj.multisig != nil {
                let confirmationStatus = wallet.confirmationStatusForTransaction(transaction: histObj)
                if confirmationStatus != .waiting {
                    result = true
                }
            }
            
            return result
        }
    }
    
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
            }
        }
    }
    
    func confirmMultisigTx() {
        transctionVC?.spiner.startAnimating()
        
        DataManager.shared.getWallet(primaryKey: wallet.multisigWallet!.linkedWalletID) { [unowned self] in
            switch $0 {
            case .success(let wallet):
                let linkedWallet = wallet
                DataManager.shared.estimation(for: "price") { [unowned self] in
                    switch $0 {
                    case .success(let value):
                        let gasLimit = value["confirmTransaction"] as? NSNumber
                        guard gasLimit != nil else {
                            return
                        }
                        
                        let trData = DataManager.shared.confirmMultiSigTx(binaryData: &self.binaryData!,
                                                                          wallet: linkedWallet,
                                                                          balanceAmountString: linkedWallet.availableAmount.stringValue,
                                                                          sendFromAddress: self.wallet.address,
                                                                          nonce: linkedWallet.ethWallet!.nonce.intValue,
                                                                          nonceMultiSigTx: self.histObj.multisig!.index.intValue,
                                                                          gasPriceString: "\(1_000_000_000)",
                                                                          gasLimitString: gasLimit!.stringValue)
                        
                        let newAddressParams = [
                            "walletindex"   : linkedWallet.walletID.intValue,
                            "address"       : "",
                            "addressindex"  : linkedWallet.addresses.count,
                            "transaction"   : trData.message,
                            "ishd"          : NSNumber(booleanLiteral: false)
                            ] as [String : Any]
                        
                        let params = [
                            "currencyid": linkedWallet.chain,
                            "networkid" : linkedWallet.chainType,
                            "payload"   : newAddressParams
                            ] as [String : Any]
                        
                        DataManager.shared.sendHDTransaction(transactionParameters: params) { [unowned self] (dict, error) in
                            print("---------\(dict)")
                            
                            if error != nil {
                                print("sendHDTransaction Error: \(error)")
                                
                                return
                            }
                            
                            if dict!["code"] as! Int == 200 {
                                self.transctionVC?.navigationController?.popViewController(animated: true)
                            } else {
                                print(error)
                            }
                        }
                        
                        break
                    case .failure(let error):
                        print(error)
                    }
                }
                break;
            case .failure(let errorString):
                print(errorString)
                break;
            }
        }
    }
    
    func declineMultisigTx() {
        transctionVC?.spiner.startAnimating()
        DataManager.shared.declineMultiSigTx(wallet: wallet, histObj: histObj) {[unowned self] result in
            self.transctionVC?.spiner.stopAnimating()
            switch result {
            case .success( _):
                self.transctionVC?.navigationController?.popViewController(animated: true)
            case .failure(let error):
                print(error)
                self.transctionVC?.presentAlert(with: error)
            }
        }
    }
    
    func viewMultisigTx() {
        DataManager.shared.viewMultiSigTx(wallet: wallet, histObj: histObj) {[unowned self] result in
            switch result {
            case .success( _):
                break
            case .failure(let error):
                print(error)
            }
        }
    }
}


