//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

class DappBrowserViewController: UIViewController, UITextFieldDelegate {
    var presenter = DappBrowserPresenter()
    
    @IBOutlet weak var browserView: UIView!
    @IBOutlet weak var blockchainTypeImageView: UIImageView!
    @IBOutlet weak var backHolderViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var navigationBarView: UIView!
    @IBOutlet weak var navigationBarTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.mainVC = self
        presenter.vcViewDidLoad()        
    }
    
    func configureUI() {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        presenter.tabBarFrame = tabBarController?.tabBar.frame
        
        blockchainTypeImageView.image = UIImage(named: presenter.defaultBlockchainType.iconString)
        
        if presenter.dragonDLObj == nil {
            presenter.dragonDLObj = make()
        }
        
        (tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
        tabBarController?.tabBar.frame = presenter.tabBarFrame!
        addGesturesRecognizers()
    }
    
    func make() -> DragonDLObj {
        let settingsObj = DragonDLObj()
        if let curID = UserDefaults.standard.value(forKey: "browserCurrencyID") {
            settingsObj.chainID = curID as! Int
        } else {
            settingsObj.chainID = 60
        }
        
        if let netId = UserDefaults.standard.value(forKey: "browserNetworkID") {
            settingsObj.chaintType = netId as! Int
        } else {
            settingsObj.chaintType = 1
        }
        
        if let url = UserDefaults.standard.value(forKey: "browserDefURL") {
            settingsObj.browserURL = url as! String
        } else {
            settingsObj.browserURL = "https://dragonereum-alpha-test.firebaseapp.com"
        }
        
        return settingsObj
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presenter.vcViewDidAppear()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
        tabBarController?.tabBar.frame = presenter.tabBarFrame!
        presenter.loadETHWallets()
        presenter.vcViewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func addGesturesRecognizers() {
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGestureRecognizer(_:)))
        navigationBarView.addGestureRecognizer(panGR)
    }
    
    var touchLocation : CGPoint = .zero
    @objc func handlePanGestureRecognizer(_ sender:UIPanGestureRecognizer){
        let translation = sender.translation(in: view)
        switch sender.state {
        case .began:
            touchLocation = sender.location(in: view)
        case .changed:
            let translation = sender.location(in: view).y - touchLocation.y
            touchLocation = sender.location(in: view)
            navigationBarTopConstraint.constant += translation
            view.layoutIfNeeded()
        case .ended:
            let navigationBarBottom = navigationBarView.frame.size.height + navigationBarView.frame.origin.y
            if navigationBarBottom < navigationBarView.frame.size.height {
                navigationBarTopConstraint.constant = -navigationBarView.frame.size.height + 15
            } else {
                navigationBarTopConstraint.constant = 0
            }
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
            touchLocation = .zero
            break
        default:
            break
        }
        
        print(translation)
    }
    
    func updateUI() {
        blockchainTypeImageView.image = UIImage(named: presenter.defaultBlockchainType.iconString)
//        backButton.isHidden = presenter.isBackButtonHidden
//        backHolderViewLeadingConstraint.constant = presenter.isBackButtonHidden ? -36 : 0
        view.layoutIfNeeded()
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let urlString = textField.text
        if urlString != nil && urlString!.count > 0 {
            presenter.loadPageWithURLString(urlString!)
        }
        return true
    }
    
    @IBAction func chooseWalletAction() {
        let walletsVC = viewControllerFrom("Receive", "ReceiveStart") as! ReceiveStartViewController
        walletsVC.presenter.isNeedToPop = true
        walletsVC.presenter.preselectedWallet = presenter.wallet
        
        walletsVC.sendWalletDelegate = self.presenter

        walletsVC.presenter.displayedBlockchainOnly = presenter.defaultBlockchainType
        self.navigationController?.pushViewController(walletsVC, animated: true)
    }
    
    @IBAction func backAction(_ sender: Any) {
        presenter.loadPreviousPage()
    }
    
//    func logAnalytics() {
//        sendDonationAlertScreenPresentedAnalytics(code: donationForActivitySC)
//    }
    
    func presentNoInternet() {
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
    }
}

extension UITextField
{
    open override func draw(_ rect: CGRect) {
        self.layer.cornerRadius = 6.0
        self.layer.borderWidth = 1.0
        self.layer.borderColor = #colorLiteral(red: 0.9568627451, green: 0.9568627451, blue: 0.9568627451, alpha: 1).cgColor
        self.layer.masksToBounds = true
    }
}
