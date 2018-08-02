//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportWalletPresenter: NSObject {
    
    var imoprtVC: ImportWalletViewController?
    var account: AccountRLM?
    let blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(EOS_NET_TYPE_MAINNET.rawValue))
    
    func makePublicKeyAndGetAccNamesBy(privateKey: String) {
        let blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(EOS_NET_TYPE_TESTNET.rawValue))
        DataManager.shared.getAccount { [unowned self] (account, error) in
            if error == nil {
                self.account = account
                
                let responce = DataManager.shared.coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: privateKey)
                
                switch responce {
                case .success(let value):
                    self.getEOSAcc(by: value["publicKey"] as! String)
                    break;
                case .failure(let error):
                    print(error)
                    break;
                }
            }
        }
    }
    
    func getEOSAcc(by privateKey: String) {
        DataManager.shared.apiManager.getEOSAccount(by: privateKey) { (responce) in
            switch responce {
            case .success(let value):
                print(value)
                self.goNext(names: value)
                break;
            case .failure(let error):
                print(error)
                self.imoprtVC!.presentWrongDataAlert()
                break;
            }
        }
    }
    
    func goNext(names: [String]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let accsVC = storyboard.instantiateViewController(withIdentifier: "accsVC") as! EOSAccountsViewController
        accsVC.presenter.namesArr = names
        accsVC.presenter.account = account
        imoprtVC?.navigationController?.pushViewController(accsVC, animated: true)
    }
}
