//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class WalletSettingsPresenter: NSObject {

    var walletSettingsVC: WalletSettingsViewController?
    
    var wallet: UserWalletRLM?
    
    func delete() {
        if wallet == nil {
            print("\nWrong wallet data: wallet == nil\n")
            
            return
        }
        
        //        walletSettingsVC?.loader.text = "Deleting Wallet"
        walletSettingsVC?.loader.show(customTitle: walletSettingsVC!.localize(string: Constants.deletingString))
        
        DataManager.shared.realmManager.getAccount { [unowned self] (acc, err) in
            guard acc != nil else {
                self.walletSettingsVC?.loader.hide()
                
                return
            }
            
            DataManager.shared.deleteWallet(self.wallet!,
                                            completion: { [unowned self] in
                                                switch $0 {
                                                case .success( _):
                                                    NotificationCenter.default.post(name: NSNotification.Name("walletDeleted"), object: self.wallet!)
                                                    RealmManager.shared.deleteWallet(self.wallet!, completion: { (acc) in
                                                        self.walletSettingsVC?.loader.hide()
                                                        self.walletSettingsVC?.navigationController?.popToRootViewController(animated: true)
                                                    })
                                                    break
                                                case .failure(let error):
                                                    self.walletSettingsVC?.presentAlert(with: error)
                                                    break
                                                }
                                                
                                                
            })
        }
    }
    
    func changeWalletName() {
//        walletSettingsVC?.progressHUD.text = "Changing name"
        walletSettingsVC?.loader.show(customTitle: walletSettingsVC!.localize(string: Constants.updatingString))
        
        DataManager.shared.getAccount { [unowned self] (account, error) in
            DataManager.shared.changeWalletName(self.wallet!,
                                                newName: self.walletSettingsVC!.walletNameTF.text!.trimmingCharacters(in: .whitespaces)) { (dict, error) in
                print(dict)
                self.walletSettingsVC?.loader.hide()
                self.walletSettingsVC!.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func resync() {
        DataManager.shared.resyncWallet(wallet!) { [unowned self] in
            switch $0 {
            case .success( _):
                self.walletSettingsVC?.navigationController?.popToRootViewController(animated: true)
                break
                
            case .failure(let error):
                self.walletSettingsVC?.presentAlert(with: error)
                break
            }
        }
    }
    
    func checkDeletePossibility(completion: @escaping(_ result: Bool, _ reason: String?) -> ()) {
        if !wallet!.isEmpty {
            let message = Constants.walletAmountAlertString
            completion(false, message)
        } else {
            DataManager.shared.realmManager.getAccount { (acc, err) in
                if acc != nil {
                    if (acc!.wallets.filter{$0.multisigWallet != nil && $0.multisigWallet!.linkedWalletAddress == self.wallet!.address && $0.multisigWallet!.chainType == self.wallet!.chainType}.count > 0) {
                        let message = Constants.deleteLinkedWalletFailedString
                        completion(false, message)
                    }
                } else {
                    completion(false, nil)
                }
            }
        }
    }
}
