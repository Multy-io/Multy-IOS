//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CurrencyToExchangePresenter: NSObject {
    
    var mainVC: CurrencyToExchangeViewController?
    var availableBlockchainArray = [CurrencyObj]()   // make it from back response
    
    var walletFromExchange: UserWalletRLM?
    
    func addFakeBlockchains() {
        availableBlockchainArray = Constants.DataManager.availableBlockchains.map { blockchainType in CurrencyObj.createCurrencyObj(blockchain: blockchainType) }
        availableBlockchainArray = availableBlockchainArray.filter { currencyObj in currencyObj.currencyBlockchain != walletFromExchange?.blockchainType }
    }
    
    func checkForExistingWallet(index: Int) {
        RealmManager.shared.getAllWalletsFor(blockchainType: availableBlockchainArray[index].currencyBlockchain) { (wallets, error) in
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
