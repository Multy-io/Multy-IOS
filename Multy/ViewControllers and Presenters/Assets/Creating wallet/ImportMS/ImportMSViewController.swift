//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = ImportMSViewController

class ImportMSViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var netTypeSwitch: UISwitch!
    @IBOutlet weak var netTypeLbl: UILabel!
    @IBOutlet weak var keyTvView: UIView!
    @IBOutlet weak var privateKeyTextView: UITextView!
    @IBOutlet weak var msAddressTextView: UITextView!
    @IBOutlet weak var keyPlaceholder: UILabel!
    @IBOutlet weak var addressPlaceholder: UILabel!
    @IBOutlet weak var msTopLbl: UILabel!
    @IBOutlet weak var msAddressView: UIView!
    
    
    let presenter = ImportMSPresenter()
    var netType = 1 //main test
    var sendWalletsDelegate: SendArrayOfWallets?
    
    var loader = PreloaderView(frame: HUDFrame, text: "", image: #imageLiteral(resourceName: "walletHuge"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.importVC = self
        hideKeyboardWhenTappedAround()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setupUI() {
        msTopLbl.isHidden = !presenter.isForMS
        msAddressView.isHidden = !presenter.isForMS
        view.addSubview(loader)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func importAction(_ sender: Any) {
        presenter.makeImport()
    }
    
    @IBAction func changeNetTypeAction(_ sender: Any) {
        if netTypeSwitch.isOn {
            presenter.selectedBlockchainType.net_type = 1
        } else {
            presenter.selectedBlockchainType.net_type = 4
        }
    }
    
    func checkForEmptyTF() {
        if presenter.isForMS {
            if privateKeyTextView.text.isEmpty  {
                shakeView(viewForShake: keyTvView)
            } else if msAddressTextView.text.isEmpty {
                shakeView(viewForShake: msAddressView)
            } else {
                
            }
        } else {
            if privateKeyTextView.text.isEmpty {
                shakeView(viewForShake: keyTvView)
            } else {
                
            }
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

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}
