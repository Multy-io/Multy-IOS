//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class WaitingMembersSettingsPresenter: NSObject {
    var presentedVC : WaitingMembersSettingsViewController?
    
    var wallet: UserWalletRLM!
    var account : AccountRLM!
    
    func changeWalletName() {
        //        walletSettingsVC?.progressHUD.text = "Changing name"
        presentedVC?.loader.show(customTitle: presentedVC!.localize(string: Constants.updatingString))
        
        DataManager.shared.getAccount { (account, error) in
            DataManager.shared.changeWalletName(currencyID:self.wallet!.chain,
                                                chainType: self.wallet!.chainType,
                                                walletID: self.wallet!.walletID,
                                                newName: self.presentedVC!.walletNameTF.text!.trimmingCharacters(in: .whitespaces)) { (dict, error) in
                                                    print(dict)
                                                    self.presentedVC?.loader.hide()
                                                    self.presentedVC!.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func delete() {
        if wallet == nil {
            print("\nWrong wallet data: wallet == nil\n")
            
            return
        }
        
        presentedVC?.loader.show(customTitle: presentedVC!.localize(string: Constants.deletingString))
        
        DataManager.shared.realmManager.getAccount { (acc, err) in
            guard acc != nil else {
                self.presentedVC?.loader.hide()
                
                return
            }
            
            
        }
    }
    
    func leave() {
        
    }
}
