//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ExchangePresenter: NSObject {
    
    var exchangeVC: ExchangeViewController?
    var walletFromSending: UserWalletRLM? {
        didSet {
            updateUI()
        }
    }

    
    func updateUI() {
        exchangeVC?.sendingImg.image = UIImage(named: walletFromSending!.blockchainType.iconString)
        exchangeVC?.sendingMaxBtn.setTitle("MAX \(walletFromSending!.availableAmountString)", for: .normal)
        exchangeVC?.summarySendingImg.image = exchangeVC?.sendingImg.image
    }
    
    
    //text field section
    
    func checkIsFiatTf(textField: UITextField) -> Bool {
        if textField == exchangeVC?.sendingFiatValueTF || textField == exchangeVC?.receiveFiatValueTF {
            return true
        } else {
            return false
        }
    }
        //Delete section
    func checkForDeletingIn(textField: UITextField) -> Bool {
        if textField == exchangeVC?.sendingFiatValueTF || textField == exchangeVC?.receiveFiatValueTF {
            if textField.text == "$ " {             // "$ " default value in fiat tf
                return false
            } else if textField.text == "$ 0," || textField.text == "$ 0." {
                textField.text = "$ "
                return false
            }
        }
        
        if textField.text == "0," || textField.text == "0." {
            textField.text?.removeAll()
            return false
        }
        
        return true
    }
        // -------- done -------- //
    func checkDelimeter(textField: UITextField) -> Bool {
        if textField.text!.isEmpty || textField.text == "$ " {  // "$ " default value in fiat tf
            textField.text = "0."                                // set first 0 and than delimeter
            return false
        }
        if textField.text!.contains(".") || textField.text!.contains(",") {
            return false
        }
        return true
    }
}
