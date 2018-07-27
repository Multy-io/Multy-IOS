//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

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
//                // MARK: check this
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
                
                self.walletsArr = walletsArray.sorted(by: { $0.availableSumInCrypto > $1.availableSumInCrypto })
                self.receiveStartVC?.updateUI()
            }
        }
    }
    
    func multisigFunc(inviteCode: String) {
        isForMultisig = true
        self.inviteCode = inviteCode
        displayedBlockchainOnly = BlockchainType.init(blockchain: BLOCKCHAIN_ETHEREUM, net_type: Int(ETHEREUM_CHAIN_ID_RINKEBY.rawValue))
    }
    
    func joinRequest() {
        let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
        let waitingVC = storyboard.instantiateViewController(withIdentifier: "waitingMembers") as! WaitingMembersViewController
        DataManager.shared.joinToMultisigWith(wallet: walletsArr[selectedIndex!], inviteCode: inviteCode) { [unowned self] (answer, err) in
            if err != nil {
                return
            } else {
                self.receiveStartVC?.navigationController?.pushViewController(waitingVC, animated: true)
            }
        }
    }
}

