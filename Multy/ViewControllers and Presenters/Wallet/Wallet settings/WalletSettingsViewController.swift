//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import AMPopTip

private typealias LocalizeDelegate = WalletSettingsViewController

class WalletSettingsViewController: UIViewController,AnalyticsProtocol {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var walletNameTF: UITextField!
    @IBOutlet weak var eosRAMLabel: UILabel!
    @IBOutlet weak var eosCPULabel: UILabel!
    @IBOutlet weak var eosNETLabel: UILabel!
    @IBOutlet weak var eosParametersHolderView: UIView!
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var eosParametersHolderViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var eosRAMHelpImageView: UIImageView!
    
    @IBOutlet weak var eosCPUHelpImageView: UIImageView!
    
    @IBOutlet weak var eosNETHelpImageView: UIImageView!
    
    @IBOutlet weak var eosParametersHolderViewTopConstraint: NSLayoutConstraint!
    let presenter = WalletSettingsPresenter()
    
//    let progressHUD = ProgressHUD(text: "Deleting Wallet...")
    var loader = PreloaderView(frame: HUDFrame, text: "Updating", image: #imageLiteral(resourceName: "walletHuge"))

    override func viewDidLoad() {
        super.viewDidLoad()
        self.swipeToBack()
        walletNameTF.accessibilityIdentifier = "nameField"
        loader = PreloaderView(frame: HUDFrame, text: localize(string: Constants.updatingString), image: #imageLiteral(resourceName: "walletHuge"))
//        loader.setupUI(text: localize(string: Constants.updatingString), image: #imageLiteral(resourceName: "walletHuge"))
        view.addSubview(loader)
        
        self.presenter.walletSettingsVC = self
        self.hideKeyboardWhenTappedAround()
        self.updateUI()
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.layoutIfNeeded()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(closeWithChainTap)\(presenter.wallet!.chain)")
    }
    
    func updateUI() {
        self.walletNameTF.text = self.presenter.wallet?.name
        let blockchainType = BlockchainType.create(wallet: presenter.wallet!)
        if blockchainType.blockchain == BLOCKCHAIN_EOS {
            eosParametersHolderView.isHidden = false
            eosParametersHolderViewTopConstraint.constant = 20
            //FIXME: set valid values
            eosCPULabel.text = String(100)
            eosRAMLabel.text = String(100)
            eosNETLabel.text = String(100)
        } else {
            eosParametersHolderView.isHidden = true
            eosParametersHolderViewTopConstraint.constant = -219
        }
        view.layoutIfNeeded()
    }
    
    func showPopTip(_ text: String, fromView: UIView) {
        let popTip = PopTip()
        popTip.textColor = .white
        popTip.font = UIFont(name: "AvenirNext-Medium", size: 12)!
        popTip.bubbleColor = #colorLiteral(red: 0.01176470588, green: 0.4980392157, blue: 1, alpha: 1)
        popTip.dismissHandler = {_ in
            self.tipView.isHidden = true
        }
        tipView.isHidden = false
        let frame = fromView.convert(fromView.bounds, to: tipView)
        popTip.show(text: text, direction: .left, maxWidth: 250, in: tipView, from: frame)
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        if presenter.wallet!.isEmpty {
            let message = localize(string: Constants.deleteWalletAlertString)
            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: localize(string: Constants.yesString), style: .cancel, handler: { [unowned self] (action) in
                self.loader.show(customTitle: self.localize(string: Constants.deletingString))
                self.presenter.delete()
                self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeletedWithChain)\(self.presenter.wallet!.chain)")
            }))
            alert.addAction(UIAlertAction(title: localize(string: Constants.noString), style: .default, handler: { (action) in
                alert.dismiss(animated: true, completion: nil)
                self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeleteCancelWithChain)\(self.presenter.wallet!.chain)")
            }))
            
            self.present(alert, animated: true, completion: nil)
        } else {
            let message = localize(string: Constants.walletAmountAlertString)
            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(deleteWithChainTap)\(self.presenter.wallet!.chain)")
    }
    
    @IBAction func touchInTF(_ sender: Any) {
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(renameWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func changeWalletName(_ sender: Any) {
        if walletNameTF.text?.trimmingCharacters(in: .whitespaces).count == 0 {
            let message = localize(string: Constants.walletNameAlertString)
            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {            
            self.presenter.changeWalletName()
            sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(saveWithChainTap)\(presenter.wallet!.chain)")
        }
    }
    
    @IBAction func chooseCurrenceAction(_ sender: Any) {
        self.goToCurrency()
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(fiatWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func myPrivateAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let adressesVC = storyboard.instantiateViewController(withIdentifier: "walletAddresses") as! WalletAddresessViewController
        adressesVC.presenter.wallet = self.presenter.wallet
        adressesVC.whereFrom = self
        self.navigationController?.pushViewController(adressesVC, animated: true)
        
        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(showKeyWithChainTap)\(presenter.wallet!.chain)")
    }
    
    func goToCurrency() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let currencyVC = storyboard.instantiateViewController(withIdentifier: "currencyVC")
        self.navigationController?.pushViewController(currencyVC, animated: true)
    }
    
    @IBAction func eosRAMHelpAction(_ sender: Any) {
        let text = localize(string: Constants.eosRAMHelpMessageString)
        showPopTip(text, fromView: eosRAMHelpImageView)
        
//        let message = localize(string: Constants.eosRAMHelpMessageString)
//        let alert = UIAlertController(title: localize(string: Constants.eosRAMHelpTitleString), message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: localize(string: Constants.yesString), style: .cancel, handler: { [unowned self] (action) in
//            self.loader.show(customTitle: self.localize(string: Constants.deletingString))
//            self.presenter.delete()
//            self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeletedWithChain)\(self.presenter.wallet!.chain)")
//        }))
//        alert.addAction(UIAlertAction(title: localize(string: Constants.noString), style: .default, handler: { (action) in
//            alert.dismiss(animated: true, completion: nil)
//            self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeleteCancelWithChain)\(self.presenter.wallet!.chain)")
//        }))
//
//        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func eosCPUHelpAction(_ sender: Any) {
        let text = localize(string: Constants.eosCPUHelpMessageString)
        showPopTip(text, fromView: eosCPUHelpImageView)
    }
    
    @IBAction func eosNETHelpAction(_ sender: Any) {
        let text = localize(string: Constants.eosNETHelpMessageString)
        showPopTip(text, fromView: eosNETHelpImageView)
    }
}

extension WalletSettingsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.text?.count)! + string.count < maxNameLength {
            return true
        } else {
            return false
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Wallets"
    }
}
