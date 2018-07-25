//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import UIKit

class WaitingMembersPresenter: NSObject {
    var viewController : WaitingMembersViewController?
    
    var wallet = UserWalletRLM()
    var account : AccountRLM?
    
    var createWalletPrice = 0.001
    
    func viewControllerViewDidLoad() {
//        inviteCode = makeInviteCode()
        updateWallet()
        viewController?.openShareInviteVC()
    }

    func kickOwnerWithIndex(index: Int) {
        let owner = wallet.multisigWallet!.owners[index]
        DataManager.shared.kickFromMultisigWith(wallet: wallet, addressToKick: owner.address) { [unowned self] (answer, error) in
            if error != nil {
                return
            } else {
                self.updateWallet()
            }
        }
    }
    
    func viewControllerViewWillAppear() {
        
    }
    
    func viewControllerViewDidLayoutSubviews() {
        
    }
    
    fileprivate func updateWallet() {
        DataManager.shared.getOneMultisigWalletVerbose(inviteCode: wallet.multisigWallet!.inviteCode, blockchain: wallet.blockchainType) { [unowned self] (answer, error) in
            self.viewController?.updateUI()
        }
    }
}
