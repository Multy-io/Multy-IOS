//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportWalletViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    var account: AccountRLM?
    let blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(EOS_NET_TYPE_MAINNET.rawValue))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        hideKeyboardWhenTappedAround()
        textView.becomeFirstResponder()
    }

    @IBAction func bakcAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            doneAction()
            return false
        }
        return true
    }
    
    func doneAction() {
        let text = textView.text
        if let key = text, key.isEmpty == false {
            DataManager.shared.getAccount { [unowned self] (account, error) in
                if error == nil {
                    self.account = account
                    
                    var binData = account!.binaryDataString.createBinaryData()!
                    
                    let responce = DataManager.shared.coreLibManager.createPublicInfo(binaryData: &binData, blockchainType: self.blockchainType, privateKey: key)
                    
                    switch responce {
                    case .success(let value):
                        DispatchQueue.main.async {
                            self.getEOSAcc(by: value["publicKey"]!)
                        }
                        
                        break;
                    case .failure(let error):
                        print(error)
                        break;
                    }
                }
            }
        }
    }
    
    func getEOSAcc(by key: String) {
        DataManager.shared.apiManager.getEOSAccount(by: key) { [unowned self] (responce) in
            switch responce {
            case .success(let value):
                print(key)
                print(value)
                
                let topIndex = self.account!.topIndex(for: self.blockchainType)
                
                for index in 0..<value.count {
                    self.createEOSWallet(address: value[index], walletIndex: topIndex + UInt32(index))
                }
                
                break;
            case .failure(let error):
                print(error)
                break;
            }
        }
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
