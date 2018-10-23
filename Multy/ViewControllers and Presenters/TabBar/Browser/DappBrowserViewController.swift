//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

class DappBrowserViewController: UIViewController {
    var presenter = DappBrowserPresenter()
    var browserCoordinator: BrowserCoordinator?
    @IBOutlet weak var browserView: UIView!
    @IBOutlet weak var walletAddress: UILabel!
    @IBOutlet weak var blockchainTypeImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.mainVC = self
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        presenter.tabBarFrame = tabBarController?.tabBar.frame
        
        blockchainTypeImageView.image = UIImage(named: presenter.defaultBlockchainType.iconString)
        presenter.loadETHWallets()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        (tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
        tabBarController?.tabBar.frame = presenter.tabBarFrame!
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func chooseWalletAction() {
        let walletsVC = viewControllerFrom("Receive", "ReceiveStart") as! ReceiveStartViewController
        walletsVC.presenter.isNeedToPop = true
        walletsVC.sendWalletDelegate = self.presenter
        walletsVC.presenter.displayedBlockchainOnly = presenter.defaultBlockchainType
        self.navigationController?.pushViewController(walletsVC, animated: true)
    }
    
//    func logAnalytics() {
//        sendDonationAlertScreenPresentedAnalytics(code: donationForActivitySC)
//    }
    
    func presentNoInternet() {
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: false)
    }
}
