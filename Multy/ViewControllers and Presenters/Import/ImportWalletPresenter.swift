//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportWalletPresenter: NSObject {
    
    var imoprtVC: ImportWalletViewController?
    
    func makePublicKeyAndGetAccNamesBy(privateKey: String) {
        let blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(EOS_NET_TYPE_TESTNET.rawValue))
        DataManager.shared.getAccount { (account, error) in
            if error == nil {
                var binData = account!.binaryDataString.createBinaryData()!
                
                let responce = DataManager.shared.coreLibManager.createPublicInfo(binaryData: &binData, blockchain: blockchainType, privateKey: privateKey)
                
                switch responce {
                case .success(let value):
                    self.getEOSAcc(by: value["publicKey"]!)
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
        imoprtVC?.navigationController?.pushViewController(accsVC, animated: true)
    }
}
