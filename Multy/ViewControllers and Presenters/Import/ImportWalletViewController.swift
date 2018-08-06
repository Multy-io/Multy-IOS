//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportWalletViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var textView: UITextView!
    var delegate: EOSNewWalletProtocol?
    
    let presenter = ImportWalletPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        presenter.imoprtVC = self
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
        if textView.text.isEmpty {
            return 
        }
        
        let key = textView.text!
        
        if presenter.existingEOSPrivateKeys.contains(key) {
            let alert = UIAlertController(title: "Error", message: "You entered existing private key", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                self.navigationController?.popViewController(animated: true)
            }))
            present(alert, animated: true, completion: nil)
            
            return 
        }
        
        presenter.makePublicKeyAndGetAccNamesBy(privateKey: textView.text!)
    }

    func presentWrongDataAlert() {
        let alert = UIAlertController(title: "Error", message: "Wrong private key", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
