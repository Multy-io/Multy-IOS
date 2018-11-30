//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import ZFRippleButton

private typealias LocalizeDelegate = SendAmountViewController
private typealias SliderExtension = SendAmountViewController

class SendAmountViewController: UIViewController, UITextFieldDelegate, AnalyticsProtocol {
    @IBOutlet weak var titleLbl: UILabel! 
    @IBOutlet weak var amountTF: UITextField!
    @IBOutlet weak var topSumLbl: UILabel!
    @IBOutlet weak var topCurrencyNameLbl: UILabel!
    @IBOutlet weak var bottomSumLbl: UILabel!
    @IBOutlet weak var bottomCurrencyLbl: UILabel!
    @IBOutlet weak var spendableSumAndCurrencyLbl: UILabel!
    @IBOutlet weak var nextBtn: ZFRippleButton!
    @IBOutlet weak var maxBtn: UIButton!
    @IBOutlet weak var maxLbl: UILabel!
    @IBOutlet weak var btnSumLbl: UILabel!
    @IBOutlet weak var commissionSwitch: UISwitch!
    @IBOutlet weak var commissionStack: UIStackView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var swapBtn: UIButton!
    @IBOutlet weak var slideToSendHolderView: UIView!
    @IBOutlet weak var nextButtonHolderView: UIView!
    
    @IBOutlet weak var constratintNextBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var buttonsHolderBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewContentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tokenViewForHide: UIView!
    
    let presenter = SendAmountPresenter()
    let numberFormatter = NumberFormatter()
    var sliderVC : SlideViewController?
    
    var keyboardHeight : CGFloat = 0 {
        didSet {
            if oldValue != keyboardHeight {
                updateConstraints()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.vc = self
        presenter.vcViewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        presenter.vcViewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.vcViewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter.vcViewWillDisappear()
    }
    
    func configure() {
        enableSwipeToBack()
        numberFormatter.numberStyle = .decimal
        
        if presenter.isPayForComissionCanBeChanged {
            commissionStack.isHidden = false
            commissionSwitch.setOn(presenter.payForCommission, animated: false)
        } else {
            commissionStack.isHidden = true
        }
        
        if presenter.tokenWallet != nil {
            tokenViewForHide.isHidden = false
            commissionSwitch.isUserInteractionEnabled = false
            swapBtn.isUserInteractionEnabled = false
        }
    }
    
    func updateUI() {
        if presenter.transactionDTO.choosenWallet!.isMultiSig {
            commissionStack.isHidden = true
            commissionSwitch.isOn = false
        }

        amountTF.text = presenter.sendAmountString
        topSumLbl.text = presenter.sendAmountString
        topCurrencyNameLbl.text = presenter.isCrypto ? " " + presenter.cryptoName : " " + presenter.fiatName
        bottomSumLbl.text = presenter.sendTXMode == .erc20 ? "" : presenter.convertedAmountString
        bottomCurrencyLbl.text = presenter.sendTXMode == .erc20 ? "" : (presenter.isCrypto ? " " + presenter.fiatName : " " + presenter.cryptoName)
        
        spendableSumAndCurrencyLbl.text = presenter.isCrypto ? presenter.maxAllowedToSpendInChoosenCurrencyString + " " + presenter.cryptoName : presenter.availableSumInFiatString + " " + presenter.fiatName
        
        btnSumLbl.text = presenter.isCrypto ? presenter.totalSumInCryptoString + " " + presenter.cryptoName : presenter.totalSumInFiatString + " " + presenter.fiatName
    }
    
    func updateConstraints() {
        buttonsHolderBottomConstraint.constant = keyboardHeight - bottomLayoutGuide.length
        scrollViewContentHeightConstraint.constant = screenHeight - nextBtn.frame.height - buttonsHolderBottomConstraint.constant - scrollView.frame.origin.y - bottomLayoutGuide.length
        view.updateConstraints()
    }
    
    @objc func hideKeyboard() {
        self.amountTF.resignFirstResponder()
    }
    
    @objc func showKeyboard() {
        self.amountTF.becomeFirstResponder()
    }
    
    func prepareButtonsHolderUI() {
        if presenter.sendFromThisScreen {
            slideToSendHolderView.isHidden = false
            nextButtonHolderView.isHidden = true
            let sendStoryboard = UIStoryboard(name: "Send", bundle: nil)
            sliderVC = sendStoryboard.instantiateViewController(withIdentifier: "sliderVC") as? SlideViewController
            sliderVC!.delegate = self
            add(sliderVC!, to: slideToSendHolderView)
        } else {
            slideToSendHolderView.isHidden = true
            nextButtonHolderView.isHidden = false
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var prevAmount = textField.text
        let changeSymbol = string
        if prevAmount == "" || (prevAmount == "0" && changeSymbol != "," && changeSymbol != "." && !changeSymbol.isEmpty) {
            if !presenter.isPossibleToSpendAmount(changeSymbol) {
                presentWarning(message: localize(string: Constants.youTryingSpendMoreThenHaveString))
                
                return false
            }
        }
        
        if let prevAmountString = prevAmount {
            if prevAmountString == "0" && changeSymbol != "," && changeSymbol != "." && !changeSymbol.isEmpty {
                prevAmount = ""
            } else if prevAmountString.isEmpty && (string == "," || string == ".") {
                return false
            }
        }
        
        let changedAmountString = (prevAmount! + changeSymbol)
        if (changeSymbol != "" && changeSymbol != "," && changeSymbol != ".") && !presenter.isPossibleToSpendAmount(changedAmountString)  {
            self.presentWarning(message: localize(string: Constants.moreThenYouHaveString))
            
            return false
        }

        let newLength = prevAmount!.count + changeSymbol.count - range.length
        
        if newLength <= self.presenter.maxLengthForSum {
            let changedAmountString =  prevAmount! + changeSymbol
            
            if (changeSymbol == "," || changeSymbol == ".") && (prevAmount?.contains(","))!{
                return false
            }
            
            if (prevAmount?.contains(","))! && changeSymbol != "" {
                let strAfterDot: [String?] = (prevAmount?.components(separatedBy: ","))!
                if self.presenter.isCrypto {
                    if strAfterDot[1]?.count == 8 {
                        return false
                    } else {
                        presenter.changeSendAmountString(changedAmountString)
                    }
                } else {
                    if strAfterDot[1]?.count == 2 {
                        return false
                    } else {
                        presenter.changeSendAmountString(changedAmountString)
                    }
                }
            } else {
                var sendAmountString = presenter.sendAmountString
                if changeSymbol == "," || changeSymbol == "." {
                    sendAmountString = changedAmountString
                } else {
                    if changeSymbol != "" {
                        sendAmountString = changedAmountString
                    } else {
                        sendAmountString.removeLast()
                        if sendAmountString == "" {
                            sendAmountString = "0"
                        }
                    }
                }
                
                presenter.changeSendAmountString(sendAmountString)
            }
        }
        
        return false
    }
    
    func segueToFinish() {
        performSegue(withIdentifier: "sendFinishVC", sender: Any.self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendFinishVC" {
            let sendAmountVC = segue.destination as! SendFinishViewController
            sendAmountVC.presenter.transactionDTO = presenter.transactionDTO
        }
    }
    
    func sendingTxDidFailed(_ error: Error?) {
        if error != nil {
            sendAnalyticsEvent(screenName: self.className, eventName: (error! as NSError).userInfo.debugDescription)
        }
        
        presentAlert(withTitle: localize(string: Constants.warningString), andMessage: localize(string: Constants.errorSendingTxString))
        print("sendHDTransaction Error: \(error)")
        sliderVC?.slideToStart()
        sendAnalyticsEvent(screenName: "\(screenSendAmountWithChain)\(presenter.transactionDTO.choosenWallet!.chain)", eventName: transactionErrorFromServer)
    }
    
    func goToSendingSuceededScreen() {
        let storyboard = UIStoryboard(name: "Send", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SuccessSendVC") as! SendingAnimationViewController
        vc.presenter.transactionAmount = presenter.totalSumInCryptoString
        vc.presenter.transactionAddress = presenter.transactionDTO.sendAddress
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.tabBarController?.selectedIndex = 0
        self.navigationController?.popToRootViewController(animated: false)
        
        sendAnalyticsEvent(screenName: "\(screenSendAmountWithChain)\(presenter.transactionDTO.choosenWallet!.chain)", eventName: cancelTap)
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func clearAction(_ sender: Any) {
        presenter.resetAmount()
    }
    
    @IBAction func payForCommisionAction(_ sender: Any) {
        presenter.payForCommission = commissionSwitch.isOn
    }
    
    @IBAction func swapAction(_ sender: Any) {
        presenter.swapCurrencies()
        sendAnalyticsEvent(screenName: "\(screenSendAmountWithChain)\(presenter.transactionDTO.choosenWallet!.chain)", eventName: switchTap)
    }
    
    @IBAction func topAmountAction(_ sender: Any) {
        var tap = ""
        if self.presenter.isCrypto {
            tap = cryptoTap
        } else {
            tap = fiatTap
        }
        sendAnalyticsEvent(screenName: "\(screenSendAmountWithChain)\(presenter.transactionDTO.choosenWallet!.chain)", eventName: tap)
    }
    
    @IBAction func bottomAmountAction(_ sender: Any) {
        var tap = ""
        if self.presenter.isCrypto {
            tap = cryptoTap
        } else {
            tap = fiatTap
        }
        sendAnalyticsEvent(screenName: "\(screenSendAmountWithChain)\(presenter.transactionDTO.choosenWallet!.chain)", eventName: tap)
    }
    
    @IBAction func sendAllAction(_ sender: Any) {
        if presenter.sendTXMode != .erc20 {
            commissionSwitch.isOn = false
        }
        
        presenter.setSumToMaxAllowed()
        
        sendAnalyticsEvent(screenName: "\(screenSendAmountWithChain)\(presenter.transactionDTO.choosenWallet!.chain)", eventName: payMaxTap)
    }
    
    @IBAction func nextAction(_ sender: Any) {
        presenter.goToFinish()
    }
}

extension SliderExtension : SliderDelegate {
    func didSlideToSend(_ sender: SlideViewController) {
        presenter.sendTx()
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Sends"
    }
}
