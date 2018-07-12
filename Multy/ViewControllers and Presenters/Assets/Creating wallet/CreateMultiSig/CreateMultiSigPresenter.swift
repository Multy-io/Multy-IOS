//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CreateMultiSigPresenter: NSObject, CountOfProtocol {
    var mainVC: CreateMultiSigViewController?
    
    var membersCount = 2
    var signaturesCount = 2
    var walletName: String = ""
    
    func passMultiSigInfo(signaturesCount: Int, membersCount: Int) {
        self.signaturesCount = signaturesCount
        self.membersCount = membersCount
        
        mainVC?.tableView.reloadData()
    }
}
