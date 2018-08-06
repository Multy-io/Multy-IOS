//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportWalletPresenter: NSObject {
    
    var imoprtVC: ImportWalletViewController?
    var account: AccountRLM?
    var blockchainType : BlockchainType!
    var netType = EOS_NET_TYPE_MAINNET {
        didSet {
            blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(netType.rawValue))
            imoprtVC?.updateNetType()
        }
    }
    
    override init() {
        super.init()
        
        netType = EOS_NET_TYPE_MAINNET
    }
    
    func makePublicKeyAndGetAccNamesBy(privateKey: String) {
        let blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(EOS_NET_TYPE_TESTNET.rawValue))
        DataManager.shared.getAccount { [unowned self] (account, error) in
            if error == nil {
                self.account = account
                
                let responce = DataManager.shared.coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: privateKey)
                
                switch responce {
                case .success(let value):
                    self.getEOSAcc(by: value["publicKey"]! as! String, privateKey: privateKey)
                    break;
                case .failure(let error):
                    print(error)
                    break;
                }
            }
        }
    }
    
    func getEOSAcc(by publicKey: String, privateKey: String) {
        DataManager.shared.apiManager.getEOSAccount(by: publicKey) { (responce) in
            switch responce {
            case .success(let value):
                print(value)
                self.goNext(names: value, publicKey: publicKey, privateKey: privateKey)
                break;
            case .failure(let error):
                print(error)
                self.imoprtVC!.presentWrongDataAlert()
                break;
            }
        }
    }
    
    func goNext(names: [String], publicKey: String, privateKey: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let accsVC = storyboard.instantiateViewController(withIdentifier: "accsVC") as! EOSAccountsViewController
        accsVC.presenter.namesArr = names
        accsVC.presenter.account = account
        accsVC.presenter.publicKey = publicKey
        accsVC.presenter.privateKey = privateKey
        accsVC.delegate = imoprtVC?.delegate
        
        imoprtVC?.navigationController?.pushViewController(accsVC, animated: true)
    }
}
