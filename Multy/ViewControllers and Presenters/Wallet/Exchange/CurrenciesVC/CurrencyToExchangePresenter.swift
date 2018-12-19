//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CurrencyToExchangePresenter: NSObject {
    
    var mainVC: CurrencyToExchangeViewController?
    
    var availableAssetsArray = [CurrencyObj]()   // make it from back response
    
    var walletFromExchange: UserWalletRLM?
    
    var sendNewWalletDelegate: SendWalletProtocol?
    
    var availableTokens = Array<TokenRLM>()
    
    func addAssetsTypes() {
        availableAssetsArray = Constants.DataManager.availableBlockchains.filter { $0.isMainnet && ($0 != walletFromExchange?.blockchainType) }.map { CurrencyObj.createCurrencyObj(blockchain: $0) }//mainnet only
        availableAssetsArray.append(contentsOf: availableTokens.map { CurrencyObj.createCurrencyObj(erc20Token: $0) }.sorted(by: { $0.currencyShortName < $1.currencyShortName }) )
    }
    
    func checkForExistingWallet(index: Int) {
//        let blockchainToReceive = walletFromSending?.blockchain == BLOCKCHAIN_ETHEREUM ? BlockchainType(blockchain: BLOCKCHAIN_BITCOIN, net_type: 0) : BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: 1)
//        RealmManager.shared.getAllWalletsFor(blockchainType: blockchainToReceive) { (wallets, error) in
//            let storyboard = UIStoryboard(name: "Receive", bundle: nil)
//            let walletsVC = storyboard.instantiateViewController(withIdentifier: "ReceiveStart") as! ReceiveStartViewController
//            walletsVC.presenter.walletsArr = Array(wallets!)
//            walletsVC.presenter.isNeedToPop = true
//            walletsVC.whereFrom = self.exchangeVC
//            walletsVC.sendWalletDelegate = self//self.mainVC?.sendWalletDelegate
//            walletsVC.presenter.displayedBlockchainOnly = blockchainToReceive
//            self.exchangeVC!.navigationController?.pushViewController(walletsVC, animated: true)
//        }
        
        RealmManager.shared.getAllWalletsFor(blockchainType: availableAssetsArray[index].currencyBlockchain) { (wallets, error) in
            if wallets != nil && (wallets?.count)! > 0 {
                let storyboard = UIStoryboard(name: "Receive", bundle: nil)
                let walletsVC = storyboard.instantiateViewController(withIdentifier: "ReceiveStart") as! ReceiveStartViewController
                walletsVC.presenter.walletsArr = Array(wallets!)
                walletsVC.presenter.isNeedToPop = true
                walletsVC.whereFrom = self.mainVC
                walletsVC.sendWalletDelegate = self.mainVC?.sendWalletDelegate
                self.mainVC?.navigationController?.pushViewController(walletsVC, animated: true)
            } else {
                let alert = UIAlertController(title: "Attantion", message: "We crete wallet for this blockchain automatically", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    //delegate
                    self.sendNewWalletDelegate?.sendWallet(wallet: DataManager.shared.createTempWallet(blockchainType: self.availableAssetsArray[index].currencyBlockchain))
                    self.mainVC?.navigationController?.popViewController(animated: true)
                }))
                alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                    alert.dismiss(animated: true, completion: nil)
                }))
                self.mainVC?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    
}
