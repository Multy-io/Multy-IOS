//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

class EOSAccountsPresenter: NSObject {
    
    var account: AccountRLM?
    var namesArr = [String]()
    let blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(EOS_NET_TYPE_TESTNET.rawValue))
    
    var mainVC : EOSAccountsViewController?
    
    var privateKey: String?
    var publicKey: String?
    var wallets = [UserWalletRLM]()
    
    func presentedViewDidLoad() {
    }
    
    func presentedViewWillAppear() {
    }
    
    func createWallets() {
        let topIndex = account!.topIndex(for: blockchainType)
        
        for index in 0..<namesArr.count {
            createEOSWallet(address: namesArr[index], walletIndex: UInt32(index) + topIndex, isFinish: (index == namesArr.count - 1))
        }
    }
    
    func createEOSWallet(address: String, walletIndex: UInt32, isFinish: Bool) {
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
                self.createWalletInDB(params: params as NSDictionary, privateKey: self.privateKey!, publicKey: self.publicKey!)
                
                if isFinish {
                    self.mainVC?.delegate?.passNewEOSWalletData(self.wallets)
                    
                    self.mainVC?.cancelAction(AnyClass.self)
                }
            } else {
                //error
            }
        }
    }
    
    func createWalletInDB(params: NSDictionary, privateKey: String, publicKey: String) {
        let wallet = UserWalletRLM()
        
        wallet.eosPublicKey = publicKey
        wallet.eosPrivateKey = privateKey
        wallet.name = params["walletName"] as! String
        wallet.address = params["address"] as! String
        
        wallets.append(wallet)
    }
}
