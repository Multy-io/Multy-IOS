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
        
    }
    
}
