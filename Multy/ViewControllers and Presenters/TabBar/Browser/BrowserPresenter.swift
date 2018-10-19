//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

class DappBrowserPresenter: NSObject {
    weak var mainVC: DappBrowserViewController?
    var tabBarFrame: CGRect?
    
    weak var delegate: SendWalletProtocol?
    var walletAddtess: String? {
        didSet {
            mainVC?.walletAddress.text = walletAddtess
        }
    }
    
    func loadETHWallets() {
        DataManager.shared.getWalletsVerbose() { [unowned self] (walletsArrayFromApi, err) in
            if err != nil {
                return
            } else {
                let walletsArray = UserWalletRLM.initArrayWithArray(walletsArray: walletsArrayFromApi!)
                let choosenWallet = walletsArray.filter { $0.blockchainType == BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: 1) }.sorted(by: { return $0.allETHBalance > $1.allETHBalance }).first
                
                DispatchQueue.main.async { [unowned self] in
                    self.walletAddtess = choosenWallet?.address
                }
            }
        }
    }
}

extension DappBrowserPresenter: SendWalletProtocol {
    func sendWallet(wallet: UserWalletRLM) {
        self.walletAddtess = wallet.address
    }
}
