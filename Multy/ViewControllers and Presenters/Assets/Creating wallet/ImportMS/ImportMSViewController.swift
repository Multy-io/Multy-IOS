//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ImportMSViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var privateKeyTextView: UITextView!
    @IBOutlet weak var msAddressTextView: UITextView!
    @IBOutlet weak var keyPlaceholder: UILabel!
    @IBOutlet weak var addressPlaceholder: UILabel!
    
    
    let presenter = ImportMSPresenter()

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
        presenter.importMSWallet { (success) in
            
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
