//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import UIKit

enum BottomButtonStatus: Int {
    case
        hidden =            1,
        inviteCode =        2,
        paymentRequired =   3
}

class WaitingMembersPresenter: NSObject {
    var viewController : WaitingMembersViewController?
    
    var wallet = UserWalletRLM()
    var account : AccountRLM?
    
    var createWalletPrice = 0.001
    
    var bottomButtonStatus = BottomButtonStatus.hidden
    
    func viewControllerViewDidLoad() {
//        inviteCode = makeInviteCode()
//        viewController?.openShareInviteVC()
        updateWallet()
    }
    
    func viewControllerViewWillAppear() {
        //        inviteCode = makeInviteCode()
   //     viewController?.openShareInviteVC()
        updateWallet()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateWallet), name: NSNotification.Name("msMembersUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleWalletDeletedNotification), name: NSNotification.Name("msWalletDeleted"), object: nil)
    }
    
    func viewControllerViewWillDisappear() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msMembersUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msWalletDeleted"), object: nil)
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
    
    @objc fileprivate func handleWalletDeletedNotification() {
        if !(wallet.multisigWallet?.amICreator)! {
            self.viewController?.navigationController?.popToRootViewController(animated: true)
        }
    }
        
    @objc fileprivate func updateWallet() {
        DataManager.shared.getOneMultisigWalletVerbose(inviteCode: wallet.multisigWallet!.inviteCode, blockchain: wallet.blockchainType) { [unowned self] (wallet, error) in
            if wallet != nil {
                self.wallet = wallet!
                self.viewController?.updateUI()
            }
        }
    }
    
    func payForMultiSig() {
        var binData = account!.binaryDataString.createBinaryData()!
        let ownersString = createOwnersString()
        
        let result = DataManager.shared.createMultiSigWallet(binaryData: &binData,
                                                             wallet: wallet,
                                                             creationPriceString: "1000000000000000",
                                                             gasPriceString: "1500000",
                                                             gasLimitString: "1000000000",
                                                             owners: ownersString,
                                                             confirmationsCount: UInt32(wallet.multisigWallet!.signaturesRequiredCount))
    }
    
    func createOwnersString() -> String {
        let ownersString = wallet.multisigWallet!.owners.map { $0.address }.joined(separator: ", ")
        
        return "[\(ownersString)]"
    }
}
