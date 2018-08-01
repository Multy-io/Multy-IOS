//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

class EOSAccountsPresenter: NSObject {
    
    var account: AccountRLM?
    var namesArr = [String]()
    let blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(EOS_NET_TYPE_MAINNET.rawValue))
    
    var mainVC : EOSAccountsViewController?
    
    func presentedViewDidLoad() {
    }
    
    func presentedViewWillAppear() {
    }
    
    func createWallets() {
        let topIndex = account!.topIndex(for: blockchainType)
        for index in 0..<namesArr.count {
            createEOSWallet(address: namesArr[index], walletIndex: UInt32(index) + topIndex)
        }
        
        mainVC?.cancelAction(AnyClass.self)
    }
    
    func createEOSWallet(address: String, walletIndex: UInt32) {
        let params = [
            "currencyID"    : blockchainType.blockchain.rawValue,
            "networkID"     : blockchainType.net_type,
            "address"       : address,
            "addressIndex"  : 0,
            "walletIndex"   : walletIndex,
            "walletName"    : address
            ] as [String : Any]
        
        DataManager.shared.addWallet(params: params) { [unowned self] (dict, error) in
            if error == nil {
                
            } else {
                //                self.mainVC?.presentAlert(with: self.localize(string: Constants.errorWhileCreatingWalletString))
            }
        }
    }
}
