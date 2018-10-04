//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CreatingWalletActionsViewController: UIViewController, CancelProtocol, AnalyticsProtocol {

    @IBOutlet weak var viewWithBtns: UIView!
    @IBOutlet weak var botConstraint: NSLayoutConstraint!
    
    weak var cancelDelegate: CancelProtocol?
    weak var createProtocol: CreateWalletProtocol?
    
    let transition = CATransition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
        self.setPresentedVcToDelegate()
        
        transition.duration = 0.4
//        transition.type = kCATransitionReveal
        transition.type = kCATransition
        transition.subtype = kCATransitionFromBottom
        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        
//        self.botConstraint.constant = -600
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5) {
            self.botConstraint.constant = 11
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.4, animations: {
            self.botConstraint.constant = -600
            self.view.layoutIfNeeded()
            self.dismiss(animated: true, completion: nil)
        }) { (success) in
            self.dismiss(animated: true, completion: nil)
        }
        
        self.cancelDelegate?.presentNoInternet()
    }
    
    @IBAction func cancelAction(_ sender: Any) {
//        self.dismiss(animated: true, completion: nil)
        UIView.animate(withDuration: 0.4, animations: {
            self.botConstraint.constant = -600
            self.view.layoutIfNeeded()
        }) { (success) in
            self.dismiss(animated: true, completion: nil)
        }
        self.cancelDelegate?.presentNoInternet()
    }
    
    @IBAction func createAction(_ sender: Any) {
        ((cancelDelegate! as! AssetsViewController).tabBarController! as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
        self.dismiss(animated: true) {
            self.createProtocol?.goToCreateWallet(tag: "createNewWallet")
        }       
    }
    
    @IBAction func createEthMultiSigAction(_ sender: Any) {
        ((cancelDelegate! as! AssetsViewController).tabBarController! as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
        self.dismiss(animated: true) {
            self.createProtocol?.goToCreateWallet(tag: "newEthMultiSig")
        }
    }
    
    @IBAction func joinToMultiSigAction(_ sender: Any) {
        ((cancelDelegate! as! AssetsViewController).tabBarController! as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
        self.dismiss(animated: true) {
            self.createProtocol?.goToCreateWallet(tag: "joinToMultiSig")
        }
    }
    
    @IBAction func importWalletAction(_ sender: Any) {
//        unowned let weakSelf =  self
//        self.presentDonationAlertVC(from: weakSelf, with: "io.multy.importWallet50")
//        logAnalytics()
        
        ((cancelDelegate! as! AssetsViewController).tabBarController! as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
        self.dismiss(animated: true) {
            self.createProtocol?.goToCreateWallet(tag: "importWallet")
        }
    }
    
    @IBAction func importMSAction(_ sender: Any) {
        //        unowned let weakSelf =  self
        //        self.presentDonationAlertVC(from: weakSelf, with: "io.multy.importWallet50")
        //        logAnalytics()
        
        ((cancelDelegate! as! AssetsViewController).tabBarController! as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
        self.dismiss(animated: true) {
            self.createProtocol?.goToCreateWallet(tag: "importMS")
        }
    }
    
    func logAnalytics() {
        sendDonationAlertScreenPresentedAnalytics(code: donationForImportWallet)
    }
    
    func cancelAction() {
        self.dismiss(animated: true) {
            self.cancelDelegate?.cancelAction()
        }
    }
    
    func donate50(idOfProduct: String) {
        self.dismiss(animated: true) {
            self.cancelDelegate?.donate50!(idOfProduct: idOfProduct)
        }
    }
    
    func presentNoInternet() {
        
    }
}

