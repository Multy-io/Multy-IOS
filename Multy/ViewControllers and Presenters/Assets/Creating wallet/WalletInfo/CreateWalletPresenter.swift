//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Firebase
//import MultyCoreLibrary

private typealias LocalizeDelegate = CreateWalletPresenter

class CreateWalletPresenter: NSObject {
    weak var mainVC: CreateWalletViewController?
    var account : AccountRLM?
    var selectedBlockchainType = BlockchainType.create(currencyID: 0, netType: 0)
    let createdWallet = UserWalletRLM()
//
    func makeAuth(completion: @escaping (_ answer: String) -> ()) {
        if self.account != nil {
            return
        }
        
        let dm = DataManager.shared
        DataManager.shared.auth(rootKey: nil) { [weak self, unowned dm] (account, error) in
//            self.assetsVC?.view.isUserInteractionEnabled = true
//            self.assetsVC?.progressHUD.hide()
            guard account != nil && self != nil else {
                return
            }
            self!.account = account
            dm.socketManager.start()
            dm.subscribeToFirebaseMessaging()
            completion("ok")
        }
    }
    
    func createNewWallet(completion: @escaping (_ dict: Dictionary<String, Any>?) -> ()) {
        if account == nil {
//            print("-------------ERROR: Account nil")
//            return
            self.makeAuth(completion: { [weak self] (answer) in
                if self != nil {
                    self!.create()
                }
            })
        } else {
            self.create()
        }
    }
    
    func create() {
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
        let cell = mainVC?.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! CreateWalletNameTableViewCell
        
        createdWallet.chain = NSNumber(value: currencyID)
        createdWallet.chainType = NSNumber(value: networkID)
        createdWallet.name = cell.walletNameTF.text ?? "Wallet"
        createdWallet.walletID = currentTopIndex!.topIndex
        createdWallet.addressID = 0
        createdWallet.address = dict!["address"] as! String
        
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
            "walletName"    : createdWallet.name
            ] as [String : Any]
        
        guard mainVC!.presentNoInternetScreen() else {
            self.mainVC?.loader.hide()
            
            return
        }
        
        DataManager.shared.addWallet(params: params) { [weak self] (dict, error) in
            guard self != nil else {
                return
            }
            
            self!.mainVC?.loader.hide()
            if error == nil {
                self!.mainVC!.sendAnalyticsEvent(screenName: screenCreateWallet, eventName: cancelTap)
                self!.mainVC!.openNewlyCreatedWallet()
            } else {
                self!.mainVC?.presentAlert(with: self!.localize(string: Constants.errorWhileCreatingWalletString))
            }
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}
