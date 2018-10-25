//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

class DappBrowserPresenter: NSObject, BrowserCoordinatorDelegate {
    
    weak var mainVC: DappBrowserViewController?
    var browserCoordinator: BrowserCoordinator?
    var tabBarFrame: CGRect?
    var defaultBlockchainType = BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: 4)
    
    var isBackButtonHidden = true {
        didSet {
            if oldValue != isBackButtonHidden {
                mainVC?.updateUI()
            }
        }
    }
    
    weak var delegate: SendWalletProtocol?
    var wallet: UserWalletRLM? {
        didSet {
            if oldValue != wallet {
                mainVC?.updateUI()
            }
        }
    }
    
    var currentHistoryIndex : Int = 0 {
        didSet {
            isBackButtonHidden = currentHistoryIndex == 0
        }
    }
    
    func vcViewDidLoad() {
        tabBarFrame = mainVC?.tabBarController?.tabBar.frame
        loadETHWallets()
    }
    
    func vcViewWillAppear() {
        browserCoordinator = BrowserCoordinator()
        browserCoordinator?.delegate = self
        mainVC?.configureUI()
        mainVC?.updateUI()
        browserCoordinator!.start()
    }
    
    func vcViewDidAppear() {
    }
    
    func loadETHWallets() {
        DataManager.shared.getWalletsVerbose() { [unowned self] (walletsArrayFromApi, err) in
            if err != nil {
                return
            } else {
                let walletsArray = UserWalletRLM.initArrayWithArray(walletsArray: walletsArrayFromApi!)
                let choosenWallet = walletsArray.filter { $0.blockchainType == self.defaultBlockchainType }.sorted(by: { return $0.allETHBalance > $1.allETHBalance }).first
                
                DispatchQueue.main.async { [unowned self] in
                    self.wallet = choosenWallet
                }
            }
        }
    }
    
    func loadPreviousPage() {
        
    }
    
    func loadPageWithURLString(_ urlString: String) {
        let url = URL(string: urlString)
        if url != nil {
            browserCoordinator?.browserViewController.goTo(url: url!)
        }
    }
    
    func didSentTransaction(transaction: SentTransaction, in coordinator: BrowserCoordinator) {
        
    }
    
    func didUpdateHistory(coordinator: BrowserCoordinator) {
        
        mainVC?.updateUI()
    }
}

extension DappBrowserPresenter: SendWalletProtocol {
    func sendWallet(wallet: UserWalletRLM) {
        self.wallet = wallet
    }
}
