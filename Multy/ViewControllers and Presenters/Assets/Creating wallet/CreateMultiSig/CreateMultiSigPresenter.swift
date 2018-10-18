//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import MultyCoreLibrary

private typealias LocalizeDelegate = CreateMultiSigPresenter

class CreateMultiSigPresenter: NSObject, CountOfProtocol {
    var mainVC: CreateMultiSigViewController?
    var account : AccountRLM?
    var ownersCount = 2
    var signaturesCount = 2
    var walletName: String = ""
    var selectedBlockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_ETHEREUM, net_type: Int(ETHEREUM_CHAIN_ID_MULTISIG_MAINNET.rawValue)) {
        didSet {
            if selectedBlockchainType.net_type == Int(ETHEREUM_CHAIN_ID_MAINNET.rawValue) {
                selectedBlockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_ETHEREUM, net_type: Int(ETHEREUM_CHAIN_ID_MULTISIG_MAINNET.rawValue))
            } else if selectedBlockchainType.net_type == Int(ETHEREUM_CHAIN_ID_RINKEBY.rawValue) {
                selectedBlockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_ETHEREUM, net_type: Int(ETHEREUM_CHAIN_ID_MULTISIG_TESTNET.rawValue))
            }
            choosenWallet = nil
            mainVC?.tableView.reloadRows(at: [[0, 2]], with: .none)
        }
    }
    let createdWallet = UserWalletRLM()
    
    var choosenWallet: UserWalletRLM?
    
    func passMultiSigInfo(signaturesCount: Int, membersCount: Int) {
        self.signaturesCount = signaturesCount
        self.ownersCount = membersCount
        
        mainVC?.tableView.reloadData()
    }
    
    func makeAuth(completion: @escaping (_ answer: String) -> ()) {
        if self.account != nil {
            return
        }
        
        let dm = DataManager.shared
        DataManager.shared.auth(rootKey: nil) { [weak self, unowned dm] (account, error) in

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
                guard self != nil else {
                    return
                }
                self!.create()
            })
        } else {
            self.create()
        }
    }
    
    func create() {
        var binData : BinaryData = account!.binaryDataString.createBinaryData()!
        
        //MARK: topIndex
        let currencyID = choosenWallet!.blockchainType.blockchain.rawValue
        let networkID = choosenWallet!.blockchainType.net_type
        var currentTopIndex = account!.topIndexes.filter("currencyID = \(currencyID) AND networkID == \(networkID)").first
        
//        var currentTopIndex = account!.topIndexes.filter("currencyID = \(currencyID) AND networkID == \(networkID)").first
        
//        if currentTopIndex == nil {
            //            mainVC?.presentAlert(with: "TopIndex error data!")
//            currentTopIndex = TopIndexRLM.createDefaultIndex(currencyID: NSNumber(value: currencyID), networkID: NSNumber(value: networkID), topIndex: NSNumber(value: 0))
//        }
        
//        let dict = DataManager.shared.createNewWallet(for: &binData, blockchain: selectedBlockchainType, walletID: currentTopIndex!.topIndex.uint32Value)
        let cell = mainVC?.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as! CreateWalletNameTableViewCell
        
        createdWallet.chain = NSNumber(value: currencyID)
        createdWallet.chainType = NSNumber(value: networkID)
        createdWallet.name = cell.walletNameTF.text ?? "Wallet"

//        createdWallet.walletID = NSNumber(value: dict!["walletID"] as! UInt32)
//        createdWallet.addressID = NSNumber(value: dict!["addressID"] as! UInt32)
//        createdWallet.address = dict!["address"] as! String
        
        if createdWallet.blockchainType.blockchain == BLOCKCHAIN_ETHEREUM {
            let ethWallet = ETHWallet()
            ethWallet.balance = "0"
            ethWallet.nonce = NSNumber(value: 0)
            ethWallet.pendingWeiAmountString = "0"
            createdWallet.ethWallet = ethWallet
            if selectedBlockchainType.net_type == Int(ETHEREUM_CHAIN_ID_MULTISIG_MAINNET.rawValue) || selectedBlockchainType.net_type == Int(ETHEREUM_CHAIN_ID_MULTISIG_TESTNET.rawValue) {
                // Multisig
                createdWallet.multisigWallet = MultisigWallet()
                createdWallet.ethWallet = ethWallet
                createdWallet.multisigWallet!.chainType = NSNumber(value: selectedBlockchainType.net_type)
                createdWallet.multisigWallet!.inviteCode = makeInviteCode()
                createdWallet.multisigWallet!.ownersCount = ownersCount
                createdWallet.multisigWallet!.signaturesRequiredCount = signaturesCount
            }
        }
        
        let multisig = [
            "isMultisig": true,
            "signaturesRequired": signaturesCount,
            "ownersCount": ownersCount,
            "inviteCode": createdWallet.multisigWallet!.inviteCode
            ] as [String : Any]
        
        let params = [
            "currencyID"    : currencyID,
            "networkID"     : networkID,
            "address"       : choosenWallet!.address,
            "walletIndex"   : choosenWallet!.walletID,
            "walletName"    : createdWallet.name,
            "multisig"      : multisig
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
                self!.mainVC!.openNewlyCreatedWallet()
            } else {
                self!.mainVC?.presentAlert(with: self!.localize(string: Constants.errorWhileCreatingWalletString))
            }
        }
    }
    
    func makeInviteCode() -> String {
        let uuid = UUID().uuidString
        let deviceName = UIDevice.current.name
        let sha3String = (uuid + deviceName).sha3(.keccak224)
        
        return String(sha3String.prefix(inviteCodeCount))
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}
