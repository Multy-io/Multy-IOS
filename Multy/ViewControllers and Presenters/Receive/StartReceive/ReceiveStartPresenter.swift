//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

private typealias LocalizeDelegate = ReceiveStartPresenter

class ReceiveStartPresenter: NSObject {
    
    var receiveStartVC: ReceiveStartViewController?
    
    var isNeedToPop = false
    
    var selectedIndexPath: IndexPath? = nil
    
//    var walletsArr = [UserWalletRLM?]()
    var walletsArr = Array<UserWalletRLM>()
    
    var selectedIndex: Int?
    
    var displayedBlockchainOnly: BlockchainType?
    
    var isForMultisig = false
    var inviteCode = ""
    var blockchainForSort: BlockchainType?
    
    var titleTextKey = Constants.receiveString
    
    //test func
//    func createWallets() {
//        for index in 1...10 {
//            let wallet = UserWalletRLM()
//            wallet.name = "Ivan \(index)"
//            wallet.cryptoName = "BTC"
//            wallet.sumInCrypto = 12.345 + Double(index)
//            wallet.sumInFiat = Double(round(100*wallet.sumInCrypto * exchangeCourse)/100)
//            wallet.fiatName = "USD"
//            wallet.fiatSymbol = "$"
//            wallet.address = "3DA28WCp4Cu5LQiddJnDJJmKWvmmZAKP5K"
//
//            self.walletsArr.append(wallet)
//        }
//    }
    
    func numberOfWallets() -> Int {
        return self.walletsArr.count
    }
    
    func blockUI() {
        receiveStartVC!.loader.show(customTitle: receiveStartVC?.localize(string: Constants.gettingWalletString))
        receiveStartVC?.tableView.isUserInteractionEnabled = false
        receiveStartVC?.tabBarController?.view.isUserInteractionEnabled = false
    }
    
    func unlockUI() {
        receiveStartVC!.loader.hide()
        receiveStartVC?.tableView.isUserInteractionEnabled = true
        receiveStartVC?.tabBarController?.view.isUserInteractionEnabled = true
    }
    
    func getWallets() {
//        DataManager.shared.getAccount { (acc, err) in
//            if err == nil {
//                self.walletsArr = acc!.wallets.sorted(by: { $0.availableSumInCrypto > $1.availableSumInCrypto })
//                self.receiveStartVC?.updateUI()
//            }
//        }
        blockUI()
        DataManager.shared.getWalletsVerbose() { [unowned self] (walletsArrayFromApi, err) in
            self.unlockUI()
            if err != nil {
                return
            } else {
                var walletsArray = UserWalletRLM.initArrayWithArray(walletsArray: walletsArrayFromApi!)
                print("afterVerbose:rawdata: \(walletsArrayFromApi)")
                
                if let blockchainType = self.displayedBlockchainOnly {
                    walletsArray = walletsArray.filter{ blockchainType == $0.blockchainType }
                    if self.isForMultisig {
                        walletsArray = walletsArray.filter{ $0.multisigWallet == nil }
                    }
                }
                
                walletsArray = walletsArray.filter{ !$0.isMultiSig || ($0.isMultiSig && $0.multisigWallet!.isDeployed) }
                
                self.walletsArr = walletsArray.sorted(by: { $0.availableSumInCrypto > $1.availableSumInCrypto })
                self.receiveStartVC?.updateUI()
            }
        }
    }
    
    func multisigFunc(inviteCode: String) {
        titleTextKey = localize(string: Constants.joinWithString)
        isForMultisig = true
        self.inviteCode = inviteCode
        displayedBlockchainOnly = BlockchainType.init(blockchain: BLOCKCHAIN_ETHEREUM, net_type: Int(ETHEREUM_CHAIN_ID_RINKEBY.rawValue))
    }
    
    func joinRequest() {
        let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
        let waitingVC = storyboard.instantiateViewController(withIdentifier: "waitingMembers") as! WaitingMembersViewController
        DataManager.shared.joinToMultisigWith(wallet: walletsArr[selectedIndex!], inviteCode: inviteCode) { [unowned self] result in
            switch result {
            case .success( _):
                self.receiveStartVC?.navigationController?.pushViewController(waitingVC, animated: true)
            case .failure(let error):
                self.receiveStartVC?.presentAlert(with: error)
            }
        }
    }
    
    func createFirstWallets(blockchianType: BlockchainType, completion: @escaping (_ answer: String?,_ error: Error?) -> ()) {
        let account = DataManager.shared.realmManager.account
        var binData : BinaryData = account!.binaryDataString.createBinaryData()!
        let createdWallet = UserWalletRLM()
        //MARK: topIndex
        let currencyID = blockchianType.blockchain.rawValue
        let networkID = blockchianType.net_type
        var currentTopIndex = account!.topIndexes.filter("currencyID = \(currencyID) AND networkID == \(networkID)").first
        
        if currentTopIndex == nil {
            //            mainVC?.presentAlert(with: "TopIndex error data!")
            currentTopIndex = TopIndexRLM.createDefaultIndex(currencyID: NSNumber(value: currencyID), networkID: NSNumber(value: networkID), topIndex: NSNumber(value: 0))
        }
        
        let dict = DataManager.shared.createNewWallet(for: &binData, blockchain: blockchianType, walletID: currentTopIndex!.topIndex.uint32Value)
        
        createdWallet.chain = NSNumber(value: currencyID)
        createdWallet.chainType = NSNumber(value: networkID)
        createdWallet.name = "My First \(blockchianType.shortName) Wallet"
        createdWallet.walletID = NSNumber(value: dict!["walletID"] as! Int32)
        createdWallet.addressID = NSNumber(value: dict!["addressID"] as! Int32)
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
        
//        guard assetsVC!.presentNoInternetScreen() else {
//            self.assetsVC?.loader.hide()
//
//            return
//        }
        
        DataManager.shared.addWallet(params: params) { [unowned self] (dict, error) in
//            self.assetsVC?.loader.hide()
            if error == nil {
//                self.assetsVC!.sendAnalyticsEvent(screenName: screenCreateWallet, eventName: cancelTap)
                completion("ok", nil)
            } else {
//                self.assetsVC?.presentAlert(with: self.assetsVC!.localize(string: Constants.errorWhileCreatingWalletString))
                completion(nil, nil)
            }
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Receives"
    }
}

