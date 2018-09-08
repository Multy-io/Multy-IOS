//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportMSPresenter: NSObject {

    var importVC: ImportMSViewController?
    var account : AccountRLM?
    var selectedBlockchainType = BlockchainType.create(currencyID: 60, netType: 4)
    let createdWallet = UserWalletRLM()
    //
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
    
    func importMSWallet(address: String, completion: @escaping (_ dict: Dictionary<String, Any>?) -> ()) {
        if account == nil {
            //            print("-------------ERROR: Account nil")
            //            return
            self.makeAuth(completion: { (answer) in
                self.importMSWallet(address: address, completion: { (dict) in
                    completion(dict)
                })
                
            })
        } else {
            self.importMSWallet(address: address, completion: { (dict) in
                completion(dict)
            })
        }
    }
    
    func importMSwith(address: String, completion: @escaping (_ dict: NSDictionary) -> ()) {
        var binData : BinaryData = account!.binaryDataString.createBinaryData()!
        
        //MARK: topIndex
        let currencyID = selectedBlockchainType.blockchain.rawValue
        let networkID = selectedBlockchainType.net_type
        var currentTopIndex = account!.topIndexes.filter("currencyID = \(currencyID) AND networkID == \(networkID)").first
        
        if currentTopIndex == nil {
            //            mainVC?.presentAlert(with: "TopIndex error data!")
            currentTopIndex = TopIndexRLM.createDefaultIndex(currencyID: NSNumber(value: currencyID), networkID: NSNumber(value: networkID), topIndex: NSNumber(value: 0))
        }
        
        let dict = DataManager.shared.createNewWallet(for: &binData, blockchain: selectedBlockchainType, walletID: currentTopIndex!.topIndex.uint32Value)
        
        createdWallet.chain = NSNumber(value: currencyID)
        createdWallet.chainType = NSNumber(value: networkID)
        createdWallet.name = "imp"
        createdWallet.walletID = NSNumber(value: dict!["walletID"] as! UInt32)
        createdWallet.addressID = NSNumber(value: dict!["addressID"] as! UInt32)
        createdWallet.address = "0x54f46318d8f83c28b719ccf01ab4628e1e8f65fa"//dict!["address"] as! String
        
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
                completion(dict!)
                print("success")
            } else {
                print("fail")
            }
        }
    }
}
