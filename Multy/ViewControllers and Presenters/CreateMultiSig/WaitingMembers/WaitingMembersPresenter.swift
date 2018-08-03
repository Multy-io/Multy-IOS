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
        viewController?.openShareInviteVC()
        updateWallet()
    }
    
    func viewControllerViewWillAppear() {
        //        inviteCode = makeInviteCode()
        viewController?.openShareInviteVC()
        updateWallet()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateWallet), name: NSNotification.Name("msJoin"), object: nil)
    }
    
    func viewControllerViewWillDisappear() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msJoin"), object: nil)
    }

    func kickOwnerWithIndex(index: Int) {
        let owner = wallet.multisigWallet!.owners[index]
        DataManager.shared.kickFromMultisigWith(wallet: wallet, addressToKick: owner.address) { [unowned self] result in
            switch result {
            case .success(_):
                self.updateWallet()
            case .failure(let error):
                self.viewController?.presentAlert(with: error)
            }
        }
    }
    
    func viewControllerViewDidLayoutSubviews() {
        
    }
        
    @objc fileprivate func updateWallet() {
        DataManager.shared.getOneMultisigWalletVerbose(inviteCode: wallet.multisigWallet!.inviteCode, blockchain: wallet.blockchainType) { [unowned self] (wallet, error) in
            if wallet != nil {
                self.wallet = wallet!
                self.viewController?.updateUI()
            }
        }
    }
}
