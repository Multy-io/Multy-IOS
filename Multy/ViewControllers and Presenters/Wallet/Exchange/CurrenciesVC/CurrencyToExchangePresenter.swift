//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CurrencyToExchangePresenter: NSObject {
    
    var mainVC: CurrencyToExchangeViewController?
    
    var availableAssetsArray = [CurrencyObj]()   // make it from back response
    var filteredAssets = [CurrencyObj]()
    
    var walletFromExchange: UserWalletRLM?
    
    var sendNewWalletDelegate: SendWalletProtocol?
    
    var availableTokens = Array<TokenRLM>()
    
    func addAssetsTypes() {
        availableAssetsArray = Constants.DataManager.availableBlockchains.filter { $0.isMainnet && ($0 != walletFromExchange?.blockchainType) }.map { CurrencyObj.createCurrencyObj(blockchainType: $0) }//mainnet only
        availableAssetsArray.append(contentsOf: availableTokens.map { CurrencyObj.createCurrencyObj(erc20Token: $0) }.sorted(by: { $0.currencyShortName < $1.currencyShortName }) )
        
        filteredAssets = availableAssetsArray.filter{ _ in true }
    }
    
    func checkForExistingWallet(index: Int) {
        let choosenCurrency = filteredAssets[index]
        let choosenToken = choosenCurrency.token
        
        let filteredWallets = DataManager.shared.getActiveAccountsWalletsWithoutMSFor(blockchainType: choosenCurrency.currencyBlockchainType)
        
        if filteredWallets.count > 0 {
            let storyboard = UIStoryboard(name: "Receive", bundle: nil)
            let walletsVC = storyboard.instantiateViewController(withIdentifier: "ReceiveStart") as! ReceiveStartViewController
            walletsVC.presenter.walletsArr = Array(filteredWallets)
            walletsVC.presenter.isNeedToPop = true
            walletsVC.presenter.choosenToken = choosenToken
            walletsVC.presenter.displayedBlockchainOnly = choosenCurrency.currencyBlockchainType
            walletsVC.whereFrom = self.mainVC
            walletsVC.sendWalletDelegate = self.sendNewWalletDelegate
            self.mainVC?.navigationController?.pushViewController(walletsVC, animated: true)
        } else {
            let alert = UIAlertController(title: "Attention", message: "We crete wallet for this blockchain automatically", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                //delegate
                //FIXME: refactor
                self.createNewWalletAndGoNextScreen(blockchainType: choosenCurrency.currencyBlockchainType, choosenIndex: index)
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { [unowned self] (action) in
                alert.dismiss(animated: true, completion: nil)
            }))
            self.mainVC?.present(alert, animated: true, completion: nil)
        }
    }
    
    func filterAssets(by string: String) {
        if string.isEmpty {
            filteredAssets = availableAssetsArray.filter{ _ in true }
        } else {
            filteredAssets = availableAssetsArray.filter{ $0.currencyShortName.lowercased().contains(string.lowercased()) || $0.currencyFullName.lowercased().contains(string.lowercased()) }
        }
        
        mainVC!.tableView.reloadData()
    }
    
    func createNewWalletAndGoNextScreen(blockchainType: BlockchainType, choosenIndex: Int) {
        DataManager.shared.createWallet(blockchianType: blockchainType, completion: { [unowned self] (code, error) in
            if error != nil {
                // alert
            } else {
                self.checkForExistingWallet(index: choosenIndex)
            }
        })
    }
}
