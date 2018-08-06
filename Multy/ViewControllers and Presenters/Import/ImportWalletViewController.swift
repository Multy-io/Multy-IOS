//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportWalletViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var privateKeyHolderView: UIView!
    @IBOutlet weak var textView: UITextView!
    
    var delegate: EOSNewWalletProtocol?
    
    let presenter = ImportWalletPresenter()
    @IBOutlet weak var blockchainTypeSegmentedControl: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        presenter.imoprtVC = self
        hideKeyboardWhenTappedAround()
        textView.becomeFirstResponder()
        let myColor = #colorLiteral(red: 0.6509803922, green: 0.6941176471, blue: 0.7764705882, alpha: 0.3)
        privateKeyHolderView.setShadow(with: myColor)
        updateNetType()
    }
    
    func updateNetType() {
        var index = 0
        if presenter.netType == EOS_NET_TYPE_TESTNET {
            index = 1
        }
        blockchainTypeSegmentedControl.selectedSegmentIndex = index
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
        if textView.text.isEmpty {
            return 
        }
        
        presenter.makePublicKeyAndGetAccNamesBy(privateKey: textView.text!)
    }

    func presentWrongDataAlert() {
        let alert = UIAlertController(title: "Error", message: "Wrong private key", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func blockchainTypeValueChanged(_ sender: Any) {
        var netType = EOS_NET_TYPE_MAINNET
        if blockchainTypeSegmentedControl.selectedSegmentIndex == 1 {
            netType = EOS_NET_TYPE_TESTNET
        }
        
        presenter.netType = netType
    }
}
