//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class WaitingMembersSettingsPresenter: NSObject {
    var presentedVC : WaitingMembersSettingsViewController?
    
    var wallet =  UserWalletRLM()
    var account = AccountRLM()
    var isCreator : Bool {
        get {
            let creator = wallet.multisigWallet?.owners.filter {$0.creator == true}.first
            return account.userID == creator?.address
        }
    }
    
    func changeWalletName() {
        //        walletSettingsVC?.progressHUD.text = "Changing name"
        presentedVC?.loader.show(customTitle: presentedVC!.localize(string: Constants.updatingString))
        
        DataManager.shared.getAccount { (account, error) in
            DataManager.shared.changeWalletName(currencyID:self.wallet.chain,
                                                chainType: self.wallet.chainType,
                                                walletID: self.wallet.walletID,
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
        
        if isCreator {
            DataManager.shared.deleteMultisigWith(wallet: wallet) { [unowned self] (answer, error) in
                if error != nil {
                    return
                } else {
                    self.presentedVC?.navigationController?.popToRootViewController(animated: true)
                }
            }
        } else {
            DataManager.shared.leaveFromMultisigWith(wallet: wallet) { [unowned self] (answer, error) in
                if error != nil {
                    return
                } else {
                    self.presentedVC?.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    func leave() {
        
    }
}
