//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

private typealias BrowserCacheDelegate = DappBrowserPresenter

class DappBrowserPresenter: NSObject {
    weak var mainVC: DappBrowserViewController?
    var tabBarFrame: CGRect?
    var defaultBlockchainType = BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: 4)
    
    var deepLinkParams: NSDictionary?  //dappURL, chainID, chainType // allStrings
    
    weak var delegate: SendWalletProtocol?
    var walletAddress: String? {
        didSet {
            mainVC?.walletAddress.text = walletAddress
            self.loadWebViewContent()
        }
    }
    
    var choosenWallet = UserWalletRLM()
    
    func loadETHWallets() {
        DataManager.shared.getWalletsVerbose() { [unowned self] (walletsArrayFromApi, err) in
            if err != nil {
                return
            } else {
                let walletsArray = UserWalletRLM.initArrayWithArray(walletsArray: walletsArrayFromApi!)
                //FIXME: MS wallets
                self.choosenWallet = walletsArray.filter { $0.blockchainType == self.defaultBlockchainType }.sorted(by: { return $0.allETHBalance > $1.allETHBalance }).first!
                self.walletAddress = self.choosenWallet.address
            }
        }
    }
    
    fileprivate func loadWebViewContent() {
        clear(cache: true, cookies: true)
        
        DispatchQueue.main.async { [unowned self] in
            self.mainVC!.browserCoordinator = BrowserCoordinator(wallet: self.choosenWallet)
            self.mainVC!.add(self.mainVC!.browserCoordinator!.browserViewController, to: self.mainVC!.browserView)
            self.mainVC!.browserCoordinator!.start()
        }
    }
}

extension BrowserCacheDelegate {
    func clear(cache: Bool, cookies: Bool) {
        if cache { clearCache() }
        if cookies { clearCookies() }
    }
    
    fileprivate func clearCache() {
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
    }
    
    fileprivate func clearCookies() {
        let cookieStorage = HTTPCookieStorage.shared
        
        guard let cookies = cookieStorage.cookies else { return }
        
        cookies.forEach { cookieStorage.deleteCookie($0) }
    }
}


extension DappBrowserPresenter: SendWalletProtocol {
    func sendWallet(wallet: UserWalletRLM) {
        self.walletAddress = wallet.address
    }
}
