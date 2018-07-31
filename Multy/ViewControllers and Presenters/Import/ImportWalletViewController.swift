//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportWalletViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    
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
//        let text = textView.text
//        if text?.isEmpty == false {
//
//
//
//        }
        
        let blockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_EOS, net_type: Int(EOS_NET_TYPE_TESTNET.rawValue))
        
        let pks = ["5KJdX2hHqfgJhSf2TJjdgbYg4b4JLCRkKoyF2DSn2Dj5mvink7J", "5Jte92DsHfdQJigfZCk4tGPA1evbfN38zniftNHqcFyg9mLxbJp", "5JanB6wZj4k8wNqExKQ2aSCPdEVRHMgmDiwx2Veu5ffa4pHyvMT", "5Jy2y2AaqnH6RMEZbs5dz1ap2ZXroXWqkEZ9iYTABFK6y946p8i", "5KNcnmwteGFjSysLEGYx9Uq1GNWGNMvYgQTk8x2eDCPnBVYhjvq", "5KNcnmwteGFjSysLEGYx9Uq1GNWGNMvYgQTk8x2eDCPnBVYhjv1"]
        
        DataManager.shared.getAccount { (account, error) in
            if error == nil {
                var binData = account!.binaryDataString.createBinaryData()!
                
                for key in pks {
                    let responce = DataManager.shared.coreLibManager.createPublicInfo(binaryData: &binData, blockchain: blockchainType, privateKey: key)
                    
                    switch responce {
                    case .success(let value):
                        print(value)
                        break;
                    case .failure(let error):
                        print(error)
                        break;
                    }
                }
            }
        }
    }
}
