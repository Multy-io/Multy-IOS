//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizableDelegate = ExchangeViewController
private typealias TextFieldDelegate = ExchangeViewController

class ExchangeViewController: UIViewController {
    
    
    @IBOutlet weak var sendingImg: UIImageView!
    @IBOutlet weak var sendingCryptoName: UILabel!
    @IBOutlet weak var sendingCryptoValueTF: UITextField!
    @IBOutlet weak var sendingFiatValueTF: UITextField!
    @IBOutlet weak var sendingMaxBtn: UIButton!
    
    @IBOutlet weak var receiveCryptoImg: UIImageView!
    @IBOutlet weak var receiveCryptoNameLbl: UILabel!
    @IBOutlet weak var receiveCryptoValueTF: UITextField!
    @IBOutlet weak var receiveFiatValueTF: UITextField!
    
    @IBOutlet weak var sendToReceiveRelation: UILabel!  // 1 BTC = 0.075342 BTC
    
    @IBOutlet weak var summaryView: UIView!
    
    @IBOutlet weak var summarySendingWalletNameLbl: UILabel!
    @IBOutlet weak var summarySendingImg: UIImageView!
    @IBOutlet weak var summarySendingCryptoValueLbl: UILabel!
    @IBOutlet weak var summarySendingCryptoNameLbl: UILabel!
    @IBOutlet weak var summarySendingFiatLbl: UILabel!
    
    @IBOutlet weak var summaryReceiveWalletNameLbl: UILabel!
    @IBOutlet weak var summaryReceiveImg: UIImageView!
    @IBOutlet weak var summaryReceiveCryptoValueLbl: UILabel!
    @IBOutlet weak var summaryReceiveCryptoNameLbl: UILabel!
    @IBOutlet weak var summaryReceiveFiatLbl: UILabel!
    
    @IBOutlet weak var slideColorView: UIView!
    @IBOutlet weak var slideView: UIView!
    @IBOutlet weak var slideLabel: UILabel!
    @IBOutlet weak var arr1: UIImageView!
    @IBOutlet weak var arr2: UIImageView!
    @IBOutlet weak var arr3: UIImageView!
    @IBOutlet var arrCollection: [UIImageView]!
    
    
    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!  // 295 /246
    
    var loader = PreloaderView(frame: HUDFrame, text: "", image: #imageLiteral(resourceName: "walletHuge"))
    
    let presenter = ExchangePresenter()
    var imageArr = [#imageLiteral(resourceName: "slideToSend1"),#imageLiteral(resourceName: "slideToSend2"),#imageLiteral(resourceName: "slideToSend3")]
    var timer: Timer?
    
    var startSlideX: CGFloat = 0.0
    var finishSlideX: CGFloat = screenWidth - 33
    var isAnimateEnded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(loader)
//        loader.show(customTitle: localize(string: Constants.loadingString))
        
        presenter.exchangeVC = self
        setupUI()
        presenter.updateUI()
//        presenter.updateReceiveSection()
        sendingCryptoValueTF.delegate = self
        
        //quickex
        //FIXME: update later to other chains
//        let toBlockchain = presenter.walletFromSending!.blockchain == BLOCKCHAIN_BITCOIN ? BLOCKCHAIN_ETHEREUM : BLOCKCHAIN_BITCOIN
//
//        DataManager.shared.marketInfo(fromBlockchain: presenter.walletFromSending!.blockchain, toBlockchain: toBlockchain) { [unowned self] in
//            switch $0 {
//            case .success(let info):
//                self.presenter.marketInfo.updateMarketInfo(dict: info)
//                if self.presenter.walletToReceive != nil {
//                    self.sendingCryptoValueChanged(self)
//                }
//            case .failure(let error):
//                print(error.localized())
//            }
//
//            self.loader.hide()
//        }
        
        //changelly
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setupUI() {
        animate()
        hideKeyboardWhenTappedAround()
        
        unowned let weakSelf =  self
        sendingCryptoValueTF.addDoneCancelToolbar(onDone: (target: self, action: #selector(doneAction)), viewController: weakSelf)
        sendingFiatValueTF.addDoneCancelToolbar(onDone: (target: self, action: #selector(doneAction)), viewController: weakSelf)
        receiveCryptoValueTF.addDoneCancelToolbar(onDone: (target: self, action: #selector(doneAction)), viewController: weakSelf)
        receiveFiatValueTF.addDoneCancelToolbar(onDone: (target: self, action: #selector(doneAction)), viewController: weakSelf)
        
        startSlideX = slideView.frame.origin.x
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(slideToSend))
        slideView.addGestureRecognizer(gestureRecognizer)
        
        sendingImg.setShadow(with: #colorLiteral(red: 0.3607843137, green: 0.4784313725, blue: 0.7607843137, alpha: 0.4))
        receiveCryptoImg.setShadow(with: #colorLiteral(red: 0.3607843137, green: 0.4784313725, blue: 0.7607843137, alpha: 0.4))
    }

    
    
    
    func animate() {
        self.timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(self.decrease), userInfo: nil, repeats: true)
        RunLoop.current.add(self.timer!, forMode: RunLoopMode.commonModes)
    }
    
    @objc func decrease() {
        if self.arr1.image == imageArr[0]  {
            UIView.transition(with: self.arrCollection[0], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr1.image = self.imageArr[2] }, completion: nil)
            UIView.transition(with: self.arrCollection[1], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr2.image = self.imageArr[0] }, completion: nil)
            UIView.transition(with: self.arrCollection[2], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr3.image = self.imageArr[1] }, completion: nil)
        } else if self.arr1.image == imageArr[2] {
            UIView.transition(with: self.arrCollection[0], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr1.image = self.imageArr[1] }, completion: nil)
            UIView.transition(with: self.arrCollection[1], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr2.image = self.imageArr[2] }, completion: nil)
            UIView.transition(with: self.arrCollection[2], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr3.image = self.imageArr[0] }, completion: nil)
        } else if self.arr1.image == imageArr[1] {
            UIView.transition(with: self.arrCollection[0], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr1.image = self.imageArr[0] }, completion: nil)
            UIView.transition(with: self.arrCollection[1], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr2.image = self.imageArr[1] }, completion: nil)
            UIView.transition(with: self.arrCollection[2], duration: 0.1, options: .transitionCrossDissolve, animations: { self.arr3.image = self.imageArr[2] }, completion: nil)
        }
    }
    
    @IBAction func slideToSend(_ gestureRecognizer: UIPanGestureRecognizer) {
        if let minValue = Double(presenter.minimalValueString) {
            if let enteredValue = Double(sendingCryptoValueTF.text!) {
                if enteredValue < minValue {
                    presentAlert(with: localize(string: Constants.youEnteredTooSmallAmountString))
                }
            } else {
                presentAlert(with: localize(string: Constants.enterAmountString))
                
                return
            }
        } else {
            presentAlert(with: localize(string: Constants.enterAmountString))
            
            return
        }
        
        let translation = gestureRecognizer.translation(in: self.view)
        if isAnimateEnded {
            return
        }
        if slideView.frame.maxX + translation.x >= finishSlideX {
            UIView.animate(withDuration: 0.3) {
                self.isAnimateEnded = true
                self.slideView.frame.origin.x = self.finishSlideX - self.slideView.frame.width

                self.presenter.creatreExchangeRequest()
            }
            
            return
        }
        
        gestureRecognizer.view!.center = CGPoint(x: slideView.center.x + translation.x, y: slideView.center.y)
        gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        
        if gestureRecognizer.view!.frame.maxX < screenWidth / 2 {
            UIView.animate(withDuration: 0.3) {
                self.slideLabel.alpha = 0.5
            }
        } else if gestureRecognizer.view!.frame.maxX > screenWidth / 2 {
            UIView.animate(withDuration: 0.3) {
                self.slideLabel.alpha = 0
            }
        }
        
        if gestureRecognizer.state == .ended {
            if gestureRecognizer.view!.frame.origin.x < screenWidth - 100 {
                slideToStart()
            }
        }
    }
    
    func slideToStart() {
        UIView.animate(withDuration: 0.3) {
            self.slideView.frame.origin.x = self.startSlideX
            self.slideLabel.alpha = 1.0
            self.isAnimateEnded = false
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func doneAction() {
        view.endEditing(true)
    }
    
    @IBAction func selectChainToReceiveAction(_ sender: Any) {
//        let currenciesVC = viewControllerFrom("Wallet", "exchangeCurrencies") as! CurrencyToExchangeViewController
//        currenciesVC.presenter.walletFromExchange = presenter.walletFromSending
//        currenciesVC.sendWalletDelegate = presenter
//        currenciesVC.presenter.sendNewWalletDelegate = presenter
//        navigationController?.pushViewController(currenciesVC, animated: true)
        
//        presenter.checkForExistingWallet() // goto selecting wallet
    }
    
    @IBAction func sendingCryptoValueChanged(_ sender: Any) {
        presenter.makeSendFiatTfValue()
        presenter.setEndValueToSend()
        presenter.setEndValueToReceive()
    }
    
    @IBAction func sendingFiatValueChanged(_ sender: Any) {
        presenter.makeSendCryptoTfValue()
        presenter.setEndValueToSend()
        presenter.setEndValueToReceive()
    }
    
    @IBAction func receiveCryptoValueChanged(_ sender: Any) {
        presenter.makeReceiveFiatString()
        presenter.setEndValueToReceive()
        presenter.setEndValueToSend()
    }
    
    @IBAction func receiveFiatValueChanged(_ sender: Any) {
        presenter.makeReceiveCryptoTfValue()
        presenter.setEndValueToReceive()
        presenter.setEndValueToSend()
    }
    
    @IBAction func maxToExchangeAction(_ sender: Any) {
        sendingCryptoValueTF.text = presenter.walletFromSending!.availableAmountString
        presenter.makeSendFiatTfValue()
        presenter.setEndValueToSend()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Storyboard.toExchangeSegueID {
            let exchangeCurrencyVC = segue.destination as! CurrencyToExchangeViewController
            exchangeCurrencyVC.presenter.sendNewWalletDelegate = presenter
            exchangeCurrencyVC.presenter.availableTokens = presenter.supportedTokens
        }
    }
}

extension LocalizableDelegate: Localizable {
    var tableName: String {
        return "Wallets"
    }
}

extension TextFieldDelegate: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        switch string {
        case "":
            return presenter.deleteEnteredIn(textField: textField)
        case ",", ".":
            return presenter.delimiterEnteredIn(textField: textField)
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            return presenter.numberEnteredIn(textField: textField)
        default: break
        }
        
        return true
    }
    
    func getMarketInfoDelayed() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        
        perform(#selector(presenter.getMarketInfo), with: nil, afterDelay: 0.5)
    }
}
