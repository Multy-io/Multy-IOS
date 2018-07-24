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
    }

    func viewControllerViewWillAppear() {
    }
    
    func viewControllerViewDidLayoutSubviews() {
    }
}
