//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportMSViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var netTypeSwitch: UISwitch!
    @IBOutlet weak var netTypeLbl: UILabel!
    @IBOutlet weak var privateKeyTextView: UITextView!
    @IBOutlet weak var msAddressTextView: UITextView!
    @IBOutlet weak var keyPlaceholder: UILabel!
    @IBOutlet weak var addressPlaceholder: UILabel!
    
    
    let presenter = ImportMSPresenter()
    var netType = 1 //main test
    var sendWalletsDelegate: SendArrayOfWallets?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.importVC = self
        hideKeyboardWhenTappedAround()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func importAction(_ sender: Any) {
        let dict = DataManager.shared.importWalletBy(privateKey: privateKeyTextView.text!, blockchain: BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: netType), walletID: -1)
        if ((dict as NSDictionary?) != nil) {
            let generatedAddress = dict!["address"] as! String
            let generatedPublic = dict!["publicKey"] as! String
            presenter.importMSwith(address: generatedAddress, publicKey: generatedPublic) { (answer) in
                self.sendWalletsDelegate?.sendArrOfWallets(arrOfWallets: self.presenter.preWallets)
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func changeNetTypeAction(_ sender: Any) {
        if netTypeSwitch.isOn {
            netType = 1
        } else {
            netType = 4
        }
    }
    
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == privateKeyTextView {
            keyPlaceholder.isHidden = true
        } else if textView == msAddressTextView {
            addressPlaceholder.isHidden = true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty == true {
            if textView == privateKeyTextView {
                keyPlaceholder.isHidden = false
            } else if textView == msAddressTextView {
                addressPlaceholder.isHidden = false
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
}
