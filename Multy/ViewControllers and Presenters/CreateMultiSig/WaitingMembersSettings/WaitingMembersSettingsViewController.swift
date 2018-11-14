//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = WaitingMembersSettingsViewController
private typealias WaitingMembersSettingsTextFieldDelegate = WaitingMembersSettingsViewController
private typealias SendWalletDelegate = WaitingMembersSettingsViewController

class WaitingMembersSettingsViewController: UIViewController, AnalyticsProtocol {
    @IBOutlet weak var linkedWalletImageView: UIImageView!
    @IBOutlet weak var walletNameTF: UITextField!
    @IBOutlet weak var linkedWalletNameLabel: UILabel!
    @IBOutlet weak var linkedWalletAddressLabel: UILabel!
    @IBOutlet weak var signToSendAndTotalMembersLabel: UILabel!
    @IBOutlet weak var deleteWalletLabel: UILabel!
    
    let presenter = WaitingMembersSettingsPresenter()
    var loader = PreloaderView(frame: HUDFrame, text: "Updating", image: #imageLiteral(resourceName: "walletHuge"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.enableSwipeToBack()
        walletNameTF.accessibilityIdentifier = "nameField"
        loader = PreloaderView(frame: HUDFrame, text: localize(string: Constants.updatingString), image: #imageLiteral(resourceName: "walletHuge"))
        view.addSubview(loader)
        self.presenter.presentedVC = self
        
        self.hideKeyboardWhenTappedAround()
//        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
    }
    
    func updateUI() {
        self.walletNameTF.text = self.presenter.wallet.name
        let linkedWallet = presenter.account.wallets.filter {$0.id == self.presenter.wallet.multisigWallet!.linkedWalletID}.first
        if linkedWallet != nil {
            self.linkedWalletNameLabel.text = linkedWallet!.name
            self.linkedWalletAddressLabel.text = linkedWallet!.address
            self.linkedWalletImageView.image = UIImage(named: linkedWallet!.blockchainType.iconString)
        }
        
        signToSendAndTotalMembersLabel.text = " \(presenter.wallet.multisigWallet!.signaturesRequiredCount) of \(presenter.wallet.multisigWallet!.ownersCount)"
        self.deleteWalletLabel.text = presenter.isCreator ? localize(string: Constants.deleteString) : localize(string: Constants.leaveString)
    }
    
    func chooseAnotherWalletAction() {
        let storyboard = UIStoryboard(name: "Receive", bundle: nil)
        let walletsVC = storyboard.instantiateViewController(withIdentifier: "ReceiveStart") as! ReceiveStartViewController
        walletsVC.presenter.isNeedToPop = true
        walletsVC.presenter.displayedBlockchainOnly = presenter.wallet.blockchainType
        walletsVC.presenter.isForMultisig = true
        walletsVC.sendWalletDelegate = self
        walletsVC.presenter.titleTextKey = ""
        self.navigationController?.pushViewController(walletsVC, animated: true)
        //        sendAnalyticsEvent(screenName: "\(screenReceiveSummaryWithChain)\(presenter.wallet!.chain)", eventName: changeWalletTap)
    }
    
    @IBAction func selectLinkedWalletAction(_ sender: Any) {
        chooseAnotherWalletAction()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
//        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(closeWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func touchInTF(_ sender: Any) {
//        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(renameWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func changeWalletName(_ sender: Any) {
//        if walletNameTF.text?.trimmingCharacters(in: .whitespaces).count == 0 {
//            let message = localize(string: Constants.walletNameAlertString)
//            let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
//            self.present(alert, animated: true, completion: nil)
//        } else {
//            self.presenter.changeWalletName()
//            sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(saveWithChainTap)\(presenter.wallet!.chain)")
//        }
    }
    
    @IBAction func chooseCurrenceAction(_ sender: Any) {
        self.goToCurrency()
//        sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(presenter.wallet!.chain)", eventName: "\(fiatWithChainTap)\(presenter.wallet!.chain)")
    }
    
    func goToCurrency() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let currencyVC = storyboard.instantiateViewController(withIdentifier: "currencyVC")
        self.navigationController?.pushViewController(currencyVC, animated: true)
    }
    
    @IBAction func deleteAction(_ sender: Any) {
        let message = presenter.isCreator ? localize(string: Constants.deleteMultisigWalletAlertString) : localize(string: Constants.leaveMultisigWalletAlertString)
        let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localize(string: Constants.yesString), style: .cancel, handler: { [unowned self] (action) in
            self.presenter.delete()
            //                self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeletedWithChain)\(self.presenter.wallet!.chain)")
        }))
        alert.addAction(UIAlertAction(title: localize(string: Constants.noString), style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
            //self.sendAnalyticsEvent(screenName: "\(screenWalletSettingsWithChain)\(self.presenter.wallet!.chain)", eventName: "\(walletDeleteCancelWithChain)\(self.presenter.wallet!.chain)")
        }))
        self.present(alert, animated: true, completion: nil)
    }
}

extension WaitingMembersSettingsTextFieldDelegate: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.text?.count)! + string.count < maxNameLength {
            return true
        } else {
            return false
        }
    }
}

extension SendWalletDelegate: SendWalletProtocol {
    func sendWallet(wallet: UserWalletRLM) {
        presenter.wallet.multisigWallet?.linkedWalletID = wallet.id
        presenter.wallet.multisigWallet?.linkedWalletAddress = wallet.address
        updateUI()
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "MultiSig"
    }
}
