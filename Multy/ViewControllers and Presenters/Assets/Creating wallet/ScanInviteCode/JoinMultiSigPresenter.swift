//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class JoinMultiSigPresenter: NSObject {

    var mainVC: JoinMultiSigViewController?
    
    func jointoWalletWith(inviteCode: String) {
        if inviteCode.count < inviteCodeCount {
            mainVC!.presentAlert(with: mainVC?.localize(string: Constants.badInviteCodeString))
            return
        }
        
        mainVC!.navigationController?.popViewController(animated: true)
        mainVC!.qrDelegate?.qrData(string: inviteCode, tag: "joinMS")
    }
}
