//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

enum PopDestination {
    case exchange
    case sendTX
}

class SendingAnimationPresenter: NSObject, ReceiveSumTransferProtocol {
    var sendingAnimationVC : SendingAnimationViewController?
    
    var transactionAddress : String?
    var transactionAmount : String?
    var fromVCType: PopDestination?
    
    func viewControllerViewWillAppear() {
        sendingAnimationVC?.updateUI()
    }
    
    func fundsReceived(_ amount: String,_ address: String, fromVCType: PopDestination? = nil) {
        transactionAddress = address
        transactionAmount = amount
        
        self.fromVCType = fromVCType
    }
}
