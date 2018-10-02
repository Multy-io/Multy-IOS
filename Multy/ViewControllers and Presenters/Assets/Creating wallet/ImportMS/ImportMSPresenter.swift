//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportMSPresenter: NSObject {

    var importVC: ImportMSViewController?
    var account : AccountRLM?
    var selectedBlockchainType = BlockchainType.create(currencyID: 60, netType: 1)
    let createdWallet = UserWalletRLM()
    var preWallets = [UserWalletRLM]()
    var isForMS = true
    
    
    func makeAuth(completion: @escaping (_ answer: String) -> ()) {
        if self.account != nil {
            return
        }
        
        DataManager.shared.auth(rootKey: nil) { (account, error) in
            //            self.assetsVC?.view.isUserInteractionEnabled = true
            //            self.assetsVC?.progressHUD.hide()
            guard account != nil else {
                return
            }
            self.account = account
            DataManager.shared.socketManager.start()
            DataManager.shared.subscribeToFirebaseMessaging()
            completion("ok")
        }
    }
    
    func makeImport() {
        if checkForEmptyTF() {
            importWallet()
        }
    }
    
    func checkForEmptyTF() -> Bool {
        let keyTV = importVC!.privateKeyTextView
        let msAddressTV = importVC!.msAddressTextView
        if isForMS {
            if keyTV!.text!.isEmpty  {
                shakeView(viewForShake: importVC!.keyTvView)
                return false
            } else if msAddressTV!.text!.isEmpty {
                shakeView(viewForShake: importVC!.msAddressView)
                return false
            } else { // all fields not empty
                return true
            }
        } else {
            if keyTV!.text!.isEmpty  {
                shakeView(viewForShake: importVC!.keyTvView)
                return false
            } else {
                return true
            }
        }
    }
    
    func importWallet() {
        var generatedAddress = ""
        var generatedPublic  = ""
        let coreDict = DataManager.shared.importWalletBy(privateKey: importVC!.privateKeyTextView.text!, blockchain: selectedBlockchainType, walletID: -1)
        if ((coreDict as NSDictionary?) != nil) {
            generatedAddress = coreDict!["address"] as! String
            generatedPublic = coreDict!["publicKey"] as! String
        } else {
            //add alert: wrong text in tf
            importVC!.presentAlert(with: "Looks like you are trying to import by not private key string")
            return
        }
        
        let primaryKey = DataManager.shared.generateImportedWalletPrimaryKey(currencyID: selectedBlockchainType.blockchain.rawValue,
                                                               networkID: UInt32(selectedBlockchainType.net_type),
                                                               address: generatedAddress)
        DataManager.shared.getWallet(primaryKey: primaryKey) { [unowned self] in
            switch $0 {
            case .success(_):
                self.importMSWallet(address: generatedAddress)
                break
            case .failure(_):
                self.importWallets(address: generatedAddress, pubKey: generatedPublic)
                break
            }
        }
    }
    
    func importWallets(address: String, pubKey: String) {
        importEthWalletWith(address: address, publicKey: pubKey) { [unowned self] (answer) in
            self.importMSWallet(address: address)
        }
    }
    
    func importMSWallet(address: String) {
        if self.isForMS {
            self.importMultiSig(contractAddress: self.importVC!.msAddressTextView.text!,
                                linkedWalletAddress: address,
                                completion: { (answer, err) in
                self.sendImportedWalletByDelegateAndExit()
            })
        } else {
            self.sendImportedWalletByDelegateAndExit()
        }
    }
    
    func sendImportedWalletByDelegateAndExit() {
        importVC!.sendWalletsDelegate?.sendArrOfWallets(arrOfWallets: self.preWallets)
        importVC!.navigationController?.popViewController(animated: true)
    }
    
    func importEthWalletWith(address: String, publicKey: String, completion: @escaping (_ dict: NSDictionary) -> ()) {
        var binData : BinaryData = account!.binaryDataString.createBinaryData()!
        
        //MARK: topIndex
        let currencyID = selectedBlockchainType.blockchain.rawValue
        let networkID = selectedBlockchainType.net_type
        var currentTopIndex = account!.topIndexes.filter("currencyID = \(currencyID) AND networkID == \(networkID)").first
        
        if currentTopIndex == nil {
            //            mainVC?.presentAlert(with: "TopIndex error data!")
            currentTopIndex = TopIndexRLM.createDefaultIndex(currencyID: NSNumber(value: currencyID), networkID: NSNumber(value: networkID), topIndex: NSNumber(value: 0))
        }
        
        
        createdWallet.chain = NSNumber(value: currencyID)
        createdWallet.chainType = NSNumber(value: networkID)
        createdWallet.name = "Imported"
//        createdWallet.walletID = NSNumber(value: dict!["walletID"] as! UInt32)
//        createdWallet.addressID = NSNumber(value: dict!["addressID"] as! UInt32)
        createdWallet.address = address
        
        if createdWallet.blockchainType.blockchain == BLOCKCHAIN_ETHEREUM {
            createdWallet.ethWallet = ETHWallet()
            createdWallet.ethWallet?.balance = "0"
            createdWallet.ethWallet?.nonce = NSNumber(value: 0)
            createdWallet.ethWallet?.pendingWeiAmountString = "0"
        }
        
        let params = [
            "currencyID"    : currencyID,
            "networkID"     : networkID,
            "address"       : createdWallet.address,
            "addressIndex"  : createdWallet.addressID,
            "walletIndex"   : createdWallet.walletID,
            "walletName"    : createdWallet.name,
            "isImported"    : true
            ] as [String : Any]
        
        DataManager.shared.importWallet(params: params) { [unowned self] (dict, error) in
            if error == nil {
                self.createImportedWalletInDB(params: params as NSDictionary, privateKey: self.importVC!.privateKeyTextView.text!, publicKey: publicKey)
                print(dict!)
                completion(dict!)
                print("success")
            } else {
                print("fail")
            }
        }
    }
    
    func createImportedWalletInDB(params: NSDictionary, privateKey: String, publicKey: String) {
        let wallet = UserWalletRLM()
        
        wallet.importedPublicKey = publicKey
        wallet.importedPrivateKey = privateKey
        wallet.name = params["walletName"] as! String
        wallet.address = params["address"] as! String
        
        preWallets.append(wallet)
    }
    
    func importMultiSig(contractAddress: String, linkedWalletAddress: String, completion: @escaping (_ dict: NSDictionary?, _ error: Error?) -> ()) {
        let msParams = [
            "isMultisig"        : true,
            "signaturesRequired": nil,
            "ownersCount"       : nil,
            "inviteCode"        : "",
            "isImported"        : true,
            "contractAddress"   : contractAddress
        ] as [String : Any?]
        
        let params = [
            "currencyID"    : selectedBlockchainType.blockchain.rawValue ,
            "networkID"     : selectedBlockchainType.net_type,
            "address"       : linkedWalletAddress,
            "addressIndex"  : 0,
            "walletIndex"   : 0,
            "walletName"    : "Imported MultiSig",
            "isImported"    : true,
            "multisig"      : msParams
        ] as [String : Any]
        
        DataManager.shared.importWallet(params: params) { [unowned self] (dict, error) in
            if error == nil {
                print("success")
                print(dict!)
                completion(dict!, nil)
            } else {
                print("fail")
            }
        }
    }
}
