//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

private typealias MultisigManager = DataManager
private typealias CoreLibPrivateKeyFixManager = DataManager

extension DataManager {
//    func isDeviceJailbroken() -> Bool {
//        return coreLibManager.isDeviceJailbroken()
//    }
    
    func getMnenonicAllWords() -> Array<String> {
        return coreLibManager.mnemonicAllWords()
    }
    
    func getMnenonicArray() -> Array<String> {
        return coreLibManager.createMnemonicPhraseArray()
    }
    
    func startCoreTest() {
        coreLibManager.startTests()
    }
    
    func getRootString(from seedPhase: String) -> (String?, String?)  {
        var binaryData = coreLibManager.createSeedBinaryData(from: seedPhase)
        if binaryData != nil {
            return (coreLibManager.createExtendedKey(from: &binaryData!), nil)
        } else {
//            return (nil, "Seed phrase is too short")
            return(nil, "WRONG SEED")
        }
        
    }
    
//    func createWallet(from seedPhrase: String, currencyID : UInt32, walletID : UInt32, addressID: UInt32) -> Dictionary<String, Any>? {
//        var binaryData = coreLibManager.createSeedBinaryData(from: seedPhrase)
//        
//        
//    }
    
    func createNewWallet(for binaryData: inout BinaryData, blockchain: BlockchainType, walletID: UInt32) -> Dictionary<String, Any>? {
        return coreLibManager.createWallet(from: &binaryData,blockchain: blockchain, walletID: walletID)
    }
    
    func importWalletBy(privateKey: String, blockchain: BlockchainType, walletID: Int32) -> Dictionary<String, Any>? {
        return coreLibManager.importWallet(blockchain: blockchain, walletID: walletID, privateKey: privateKey)
    }
    
    func isAddressValid(address: String, for wallet: UserWalletRLM) -> (isValid: Bool, message: String?) {
        return coreLibManager.isAddressValid(address: address, for: wallet)
    }
    
    func isAddressValid(_ address: String, for blockchainType: BlockchainType) -> (isValid: Bool, message: String?) {
        return coreLibManager.isAddressValid(address, for: blockchainType)
    }
    
    func createAndSendDonationTransaction(transactionDTO: TransactionDTO, completion: @escaping(_ answer: String?,_ error: Error?) -> ()) {
        let core = DataManager.shared.coreLibManager
        let wallet = transactionDTO.choosenWallet!
        var binaryData = DataManager.shared.realmManager.account!.binaryDataString.createBinaryData()!
        
        
        let addressData = core.createAddress(blockchainType: transactionDTO.blockchainType!,
                                             walletID: transactionDTO.choosenWallet!.walletID.uint32Value,
                                             addressID: UInt32(transactionDTO.choosenWallet!.addresses.count),
                                             binaryData: &binaryData)
        
        let trData = DataManager.shared.coreLibManager.createTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                                         sendAddress: transactionDTO.sendAddress!,
                                                                         sendAmountString: transactionDTO.sendAmount!.fixedFraction(digits: 8),
                                                                         feePerByteAmount: "\(transactionDTO.transaction!.customFee!)",
                                                                         isDonationExists: false,
                                                                         donationAmount: "0",
                                                                         isPayCommission: false,
                                                                         wallet: transactionDTO.choosenWallet!,
                                                                         binaryData: &binaryData,
                                                                         inputs: transactionDTO.choosenWallet!.addresses)
        
        if trData.1 < 0 {
            completion(trData.0, NSError(domain: "", code: 400, userInfo: nil))
            
            return
        }

        let newAddressParams = [
            "walletindex"   : wallet.walletID.intValue,
            "address"       : addressData!["address"] as! String,
            "addressindex"  : wallet.addresses.count,
            "transaction"   : trData.0,
            "ishd"          : NSNumber(booleanLiteral: true)
            ] as [String : Any]
        
        let params = [
            "currencyid": wallet.chain,
            "payload"   : newAddressParams
            ] as [String : Any]
        
        DataManager.shared.sendHDTransaction(transactionParameters: params) { (dict, error) in
            print("---------\(dict)")
            
            //FIXME: create messages in bad cases
            if error != nil {
                print("sendHDTransaction Error: \(error)")
                completion(nil, error)
                
                return
            }
            
            if dict!["code"] as! Int == 200 {
                completion("good", nil)
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func createEtherTx(binaryData: inout BinaryData, wallet: UserWalletRLM, sendAddress: String, sendAmountString: String, gasPriceString: String, gasLimitString: String) {
        let blockchain = BlockchainType.create(wallet: wallet)
        let addressData = self.coreLibManager.createAddress(blockchainType: blockchain, walletID: wallet.walletID.uint32Value, addressID: wallet.addressID.uint32Value, binaryData: &binaryData)
        
        let _ = self.coreLibManager.createEtherTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                           sendAddress: sendAddress,
                                                           sendAmountString: sendAmountString,
                                                           nonce: wallet.ethWallet!.nonce.intValue,
                                                           balanceAmount: wallet.availableAmount.stringValue,
                                                           ethereumChainID: UInt32(4), //RINKEBY
                                                           gasPrice: gasPriceString,
                                                           gasLimit: gasLimitString)
    }
    
    func privateKeyString(blockchain: BlockchainType, walletID: UInt32, addressID: UInt32, binaryData: inout BinaryData) -> String {
        return coreLibManager.privateKeyString(blockchain: blockchain, walletID: walletID, addressID: addressID, binaryData: &binaryData)
    }
}

extension CoreLibPrivateKeyFixManager  {
    func checkWallets(_ wallets: List<UserWalletRLM>) -> [UserWalletRLM] {
        var convertedWallets = [UserWalletRLM]()
        
        guard DataManager.shared.shouldCheckWalletsPrivateKeys  else {
            return convertedWallets
        }
        
        for wallet in wallets {
            if (wallet.blockchain != BLOCKCHAIN_ETHEREUM || wallet.isImported || wallet.isMultiSig) && wallet.shouldFixPrivateKey == false {
                continue
            }
            
            var binaryData = realmManager.account!.binaryDataString.createBinaryData()!
            
            let addressData = coreLibManager.createWallet(from: &binaryData, blockchain: wallet.blockchainType, walletID: wallet.walletID.uint32Value)
            
            if addressData == nil {
                continue
            }
            
            let address = addressData!["address"] as! String
            
            if address == wallet.address { //the good case
                continue
            }
            
            let newKeysData = coreLibManager.findPrivateKey(for: wallet.address, blockchainType: wallet.blockchainType, walletID: wallet.walletID.uint32Value, binaryData: &binaryData)
            
            if newKeysData == nil {
                continue
            }
            
            let convertedWallet = wallet
            convertedWallet.importedPrivateKey = newKeysData!["privateKey"] as! String
            convertedWallet.importedPublicKey = newKeysData!["publicKey"] as! String
            convertedWallet.brokenState = NSNumber(value: 1)
            
            convertedWallets.append(convertedWallet)
        }
        
        let convertedAddresses = convertedWallets.map { $0.address }
        
        convertToBroken(convertedAddresses) { print( $0) }
        
        return convertedWallets
    }
    
    func createWalletData(currencyID: NSNumber, networkID: NSNumber, walletID: NSNumber) -> Dictionary<String, Any> {
        var binaryData = realmManager.account!.binaryDataString.createBinaryData()!
        let blockchainType = BlockchainType(blockchain: Blockchain(rawValue: currencyID.uint32Value), net_type: networkID.intValue)
        
        let addressData = coreLibManager.createAddress(blockchainType: blockchainType,
                                             walletID: walletID.uint32Value,
                                             addressID: 0,
                                             binaryData: &binaryData)
        
        return addressData!
    }
}

extension MultisigManager {
    func createMultiSigWallet(binaryData: inout BinaryData,
                              wallet: UserWalletRLM,
                              creationPriceString: String,
                              gasPriceString: String,
                              gasLimitString: String,
                              owners: String,
                              confirmationsCount: UInt32) -> (message: String, isTransactionCorrect: Bool) {
        let blockchainType = BlockchainType.create(wallet: wallet)
        var pointer : UnsafeMutablePointer<OpaquePointer?>?
        if wallet.isImported {
            let blockchainType = wallet.blockchainType
            let privatekey = wallet.importedPrivateKey
            let walletInfo = DataManager.shared.coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: privatekey)
            switch walletInfo {
            case .success(let value):
                pointer = value["pointer"] as? UnsafeMutablePointer<OpaquePointer?>
            case .failure(let error):
                print(error)
                
                return (error, false)
            }
        } else {
            let addressData = coreLibManager.createAddress(blockchainType: blockchainType, walletID: wallet.walletID.uint32Value, addressID: wallet.addressID.uint32Value, binaryData: &binaryData)
            pointer = addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>
        }
        let factoryAddress = multisigFactory(for: blockchainType)
        
        if factoryAddress == nil || factoryAddress!.isEmpty {
            return ("Missed factory address", false)
        }
        
        let multiSigWalletCreationInfo = coreLibManager.createMutiSigWallet(addressPointer: pointer!,
                                                                            creationPriceString: creationPriceString,
                                                                            factoryAddress: factoryAddress!,
                                                                            owners: owners,
                                                                            confirmationsCount: confirmationsCount,
                                                                            nonce: wallet.ethWallet!.nonce.intValue,
                                                                            balanceAmountString: wallet.availableAmount.stringValue,
                                                                            gasPriceString: gasPriceString,
                                                                            gasLimitString: gasLimitString)
        
        return multiSigWalletCreationInfo
    }
    
    func createMultiSigTx(binaryData: inout BinaryData,
                          wallet: UserWalletRLM,
                          sendFromAddress: String,
                          sendAmountString: String,
                          sendToAddress: String,
                          msWalletBalance: String,
                          gasPriceString: String,
                          gasLimitString: String) -> (message: String, isTransactionCorrect: Bool) {
        let blockchainType = BlockchainType.create(wallet: wallet)
        
        var addressData: Dictionary<String, Any>?
        
        if wallet.isImported {
            let accountDataResult = coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: wallet.importedPrivateKey)
            
            switch accountDataResult {
            case .failure(let error):
                break
            case .success(let accountData):
                addressData = ["addressPointer" : accountData["pointer"] as? UnsafeMutablePointer<OpaquePointer?>]
                break
            }
        } else {
            addressData = coreLibManager.createAddress(blockchainType: blockchainType,
                                                       walletID: wallet.walletID.uint32Value,
                                                       addressID: wallet.addressID.uint32Value,
                                                       binaryData: &binaryData)
        }
        
        if addressData == nil {
            return ("Error", false)
        }
        
        let multiSigTxCreationInfo = coreLibManager.createMultiSigTx(addressPointer:    addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                                     sendFromAddress:   sendFromAddress,
                                                                     sendAmountString:  sendAmountString,
                                                                     sendToAddress:     sendToAddress,
                                                                     nonce:             wallet.ethWallet!.nonce.intValue,
                                                                     balanceAmountString: msWalletBalance,
                                                                     gasPriceString:    gasPriceString,
                                                                     gasLimitString:    gasLimitString)
        
        return multiSigTxCreationInfo
    }
    
    func confirmMultiSigTx(binaryData: inout BinaryData,
                           wallet: UserWalletRLM,
                           balanceAmountString: String,
                           sendFromAddress: String,
                           nonce: Int,
                           nonceMultiSigTx: Int,
                           gasPriceString: String,
                           gasLimitString: String) -> (message: String, isTransactionCorrect: Bool) {
        let blockchainType = BlockchainType.create(wallet: wallet)
        
        var addressData: Dictionary<String, Any>?
        
//        if wallet.isImported {
        if wallet.isImportedForPrimaryKey {
            let accountDataResult = coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: wallet.importedPrivateKey)
            
            switch accountDataResult {
            case .failure(let error):
                break
            case .success(let accountData):
                addressData = ["addressPointer" : accountData["pointer"] as? UnsafeMutablePointer<OpaquePointer?>]
                break
            }
        } else {
            addressData = coreLibManager.createAddress(blockchainType: blockchainType,
                                                           walletID: wallet.walletID.uint32Value,
                                                           addressID: wallet.addressID.uint32Value,
                                                           binaryData: &binaryData)
        }
        
        if addressData == nil {
            return ("Error", false)
        }
        
        let multiSigTxConfirmInfo = coreLibManager.confirmMultiSigTx(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                                     sendFromAddress: sendFromAddress,
                                                                     nonce: nonce,
                                                                     nonceMultiSigTx: nonceMultiSigTx,
                                                                     balanceAmountString: balanceAmountString,
                                                                     gasPriceString: gasPriceString,
                                                                     gasLimitString: gasLimitString)
        
        return multiSigTxConfirmInfo
    }
}
