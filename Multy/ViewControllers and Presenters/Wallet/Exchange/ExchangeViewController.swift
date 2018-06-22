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
    
    @IBOutlet weak var summarySendingImg: UIImageView!
    @IBOutlet weak var summarySendingCryptoValueLbl: UILabel!
    @IBOutlet weak var summarySendingCryptoNameLbl: UILabel!
    @IBOutlet weak var summarySendingFiatLbl: UILabel!
    
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
    
    let presenter = ExchangePresenter()
    var imageArr = [#imageLiteral(resourceName: "slideToSend1"),#imageLiteral(resourceName: "slideToSend2"),#imageLiteral(resourceName: "slideToSend3")]
    var timer: Timer?
    
    var startSlideX: CGFloat = 0.0
    var finishSlideX: CGFloat = screenWidth - 33
    var isAnimateEnded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.exchangeVC = self
        setupUI()
        presenter.updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        slideColorView.applyGradient(withColours: [UIColor(ciColor: CIColor(red: 0/255, green: 178/255, blue: 255/255)),
                                                   UIColor(ciColor: CIColor(red: 0/255, green: 122/255, blue: 255/255))],
                                     gradientOrientation: .horizontal)
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
        slideView.isUserInteractionEnabled = true
        slideView.addGestureRecognizer(gestureRecognizer)
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
        let translation = gestureRecognizer.translation(in: self.view)
        if isAnimateEnded {
            return
        }
        if slideView.frame.maxX + translation.x >= finishSlideX {
            UIView.animate(withDuration: 0.3) {
                self.isAnimateEnded = true
                self.slideView.frame.origin.x = self.finishSlideX - self.slideView.frame.width
                //                self.view.isUserInteractionEnabled = false
                //EXCHANGE action
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
            return presenter.checkForDeletingIn(textField: textField)
        case ",", ".":
            return presenter.checkDelimeter(textField: textField)
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9":
            break
        default: break
        }
        return true
    }
}
