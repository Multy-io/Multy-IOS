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
        let text = textView.text
        if text?.isEmpty == false {
            let blockchain 
            make_account(<#T##blockchain: BlockchainType##BlockchainType#>, <#T##account_type: UInt32##UInt32#>, <#T##serialized_private_key: UnsafePointer<Int8>!##UnsafePointer<Int8>!#>, <#T##new_account: UnsafeMutablePointer<OpaquePointer?>!##UnsafeMutablePointer<OpaquePointer?>!#>)
        }
    }
}
