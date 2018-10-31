//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

class SendFinishPresenter: NSObject {

    var sendFinishVC: SendFinishViewController?
    var transactionDTO = TransactionDTO() {
        didSet {
            cryptoName = transactionDTO.blockchainType!.shortName
        }
    }
    
    var account = DataManager.shared.realmManager.account
    
    var selectedSpeedIndex: Int?
    
    var sumInCrypto: Double?
    var sumInCryptoString = String()
    var sumInFiat: Double?
    var sumInFiatString = String()
    
    var feeAmountInCryptoString = String()
    var feeAmountInFiatString = String()
    
    var cryptoName = "BTC"
    var fiatName = "USD" // MARK: get from settings
    
    var isCrypto = true
    var selectedAddress: String?
    
    //for new tx
    var binaryData : BinaryData?
    var addressData : Dictionary<String, Any>?
    var pointer: UnsafeMutablePointer<OpaquePointer?>?
    var updatedWallet: UserWalletRLM?
    
    func makeEndSum() {
//        switch isCrypto {
//        case true:
            if transactionDTO.choosenWallet!.blockchainType.blockchain == BLOCKCHAIN_BITCOIN {
                sumInCrypto = transactionDTO.sendAmountString?.stringWithDot.doubleValue
                sumInCryptoString = sumInCrypto!.fixedFraction(digits: 8)
                sumInFiat = sumInCrypto! * transactionDTO.choosenWallet!.exchangeCourse
                sumInFiatString = sumInFiat!.fixedFraction(digits: 2)
                
                feeAmountInCryptoString = (transactionDTO.transaction?.transactionRLM?.sumInCrypto ?? 0.0).fixedFraction(digits: 8)
                feeAmountInFiatString = (transactionDTO.transaction?.transactionRLM?.sumInFiat ?? 0.0).fixedFraction(digits: 2)
            } else if transactionDTO.choosenWallet!.blockchainType.blockchain == BLOCKCHAIN_ETHEREUM {
                sumInCryptoString = transactionDTO.sendAmountString!
                if isCrypto {
                    sumInFiatString = (transactionDTO.transaction!.endSumBigInt! * transactionDTO.choosenWallet!.exchangeCourse).fiatValueString(for: BLOCKCHAIN_ETHEREUM)
                } else {
                    sumInFiatString = (transactionDTO.transaction!.endSumBigInt!).fiatValueString(for: BLOCKCHAIN_ETHEREUM)
                }
                
                
                let feeAmount = transactionDTO.transaction!.feeAmount
                let feeAmountInWei = feeAmount * transactionDTO.choosenWallet!.exchangeCourse
                feeAmountInCryptoString = feeAmount.cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
                feeAmountInFiatString = feeAmountInWei.fiatValueString(for: BLOCKCHAIN_ETHEREUM)
            }
//        case false:
//            self.sumInFiat = transactionDTO.transaction?.endSum
//
//            self.sumInCrypto = self.sumInFiat!
//        }
    }
    
    func makeFrameForSlider() -> CGRect {
        let y = self.sendFinishVC!.scrollView.contentSize.height - 64    // 64 - height of send btn
        let frame = CGRect(x: 0, y: y, width: screenWidth, height: 64.0)
        
        return frame
    }
    
    
    func makeNewTx() {
        // fix for 'Low nonce'
        if transactionDTO.choosenWallet!.importedPrivateKey.isEmpty == false {
            return
        }
        //fixit: make norm check
        let blockchainType = BlockchainType.create(wallet: transactionDTO.choosenWallet!)
        if blockchainType.blockchain == BLOCKCHAIN_BITCOIN {
            return
        }
        
        getOneVerbose { (updatedWallet, err) in
            if updatedWallet == nil {
                //error
            }
            let core = DataManager.shared.coreLibManager
            let wallet = self.transactionDTO.choosenWallet!
            self.binaryData = self.account!.binaryDataString.createBinaryData()!
            
            if !wallet.isImported  {
                self.addressData = core.createAddress(blockchainType:    self.transactionDTO.blockchainType!,
                                                 walletID:      wallet.walletID.uint32Value,
                                                 addressID:     wallet.changeAddressIndex,
                                                 binaryData:    &self.binaryData!)
            }
            self.pointer = self.addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>
            
            let amount = self.transactionDTO.sendAmountString?.convertCryptoAmountStringToMinimalUnits(in: BLOCKCHAIN_ETHEREUM)
            
            let trData = DataManager.shared.coreLibManager.createEtherTransaction(addressPointer: self.pointer!,
                                                                                  sendAddress: self.transactionDTO.sendAddress!,
                                                                                  sendAmountString: amount!.stringValue,
                                                                                  nonce: updatedWallet!.ethWallet!.nonce.intValue,  //new nonce
                balanceAmount: "\(self.transactionDTO.choosenWallet!.ethWallet!.balance)",
                ethereumChainID: UInt32(self.transactionDTO.choosenWallet!.blockchainType.net_type),
                gasPrice: self.transactionDTO.transaction?.transactionRLM?.sumInCryptoBigInt.stringValue ?? "0",
                gasLimit: self.transactionDTO.transaction!.customGAS!.gasLimit.stringValue)
            
            self.transactionDTO.transaction?.rawTransaction = trData.message
        }
        
    }
    
    func getOneVerbose(completion: @escaping (_ updatedWallet: UserWalletRLM?,_ error: Error?) -> ()) {
        blockUI()
        var walletForUpdate: UserWalletRLM?
        if transactionDTO.choosenWallet!.isMultiSig {
            DataManager.shared.getWallet(primaryKey: transactionDTO.choosenWallet!.multisigWallet!.linkedWalletID) { (result) in
                switch result {
                case .success(let wallet):
                    walletForUpdate = wallet
                    DataManager.shared.getOneWalletVerbose(wallet: walletForUpdate!) { (updatedWallet, error) in
                        self.unlockUI()
                        if updatedWallet != nil {
                            completion(updatedWallet, nil)
                        }
                    }
                case .failure(_):
                    //fix it return error (but if we have MS how can we doesn`t have linked wallet? so error chance is minimum)
                    completion(nil, nil)
                }
            }
        } else {
            walletForUpdate = transactionDTO.choosenWallet!
            DataManager.shared.getOneWalletVerbose(wallet: walletForUpdate!) { (updatedWallet, error) in
                self.unlockUI()
                if updatedWallet != nil {
                    completion(updatedWallet, nil)
                }
            }
        }
    }
    
    
    func blockUI() {
        sendFinishVC!.view.isUserInteractionEnabled = false
        sendFinishVC!.loader.show(customTitle: "Loading...")
    }
    
    func unlockUI() {
        sendFinishVC!.view.isUserInteractionEnabled = true
        sendFinishVC!.loader.hide()
    }
    
}
