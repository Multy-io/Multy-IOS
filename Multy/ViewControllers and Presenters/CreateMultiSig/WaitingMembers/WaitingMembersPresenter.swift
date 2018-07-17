//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import UIKit

class WaitingMembersPresenter: NSObject {
    var viewController : WaitingMembersViewController?
    
    var walletName = String()
    var membersAmount: Int = 2
    var membersJoined = [String]()
    var createWalletPrice = 0.001
    var inviteCode = ""             //send it to server
    
    func viewControllerViewDidLoad() {
        inviteCode = makeInviteCode()
        viewController?.openShareInviteVC()
    }

    func viewControllerViewWillAppear() {
    }
    
    func viewControllerViewDidLayoutSubviews() {
    }
    
    func makeInviteCode() -> String {
        let uuid = UUID().uuidString
        let deviceName = UIDevice.current.name
        return (uuid + deviceName).sha3(.keccak224)
    }
    
}
