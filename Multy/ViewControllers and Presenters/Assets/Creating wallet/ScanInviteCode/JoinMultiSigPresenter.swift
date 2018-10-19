//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

class JoinMultiSigPresenter: NSObject {

    var mainVC: JoinMultiSigViewController?
    var isCanValidate = true
    
    func validate(inviteCode: String) {
        if isCanValidate == false {
            return
        }
        
        if inviteCode.count < inviteCodeCount {
            mainVC!.presentAlert(with: mainVC?.localize(string: Constants.badInviteCodeString))
            return
        }
        isCanValidate = false // for send request once
        DataManager.shared.validateInviteCode(code: inviteCode) { result in
            switch result {
            case .success(let value):
                self.mainVC?.sendAnalyticsEvent(screenName: screenJoinToMs, eventName: validationInviteQr + "Success")
                let isExists = value["exists"] as! Int
                
                if isExists != 0 {
                    let currencyID = value["currencyid"] as! UInt32
                    let networkID = value["networkid"] as! UInt32
                    let blockchainType = BlockchainType.create(currencyID: currencyID, netType: networkID)
                    self.mainVC!.navigationController?.popViewController(animated: true)
                    self.mainVC!.blockchainTransferDelegate?.setBlockchain(blockchain: blockchainType)
                    self.mainVC!.qrDelegate?.qrData(string: inviteCode, tag: "joinMS")
                } else {
                    self.mainVC!.textView.text = ""
                    self.mainVC!.captureSession?.startRunning()
                    self.mainVC!.presentAlert(with: self.mainVC?.localize(string: Constants.msIsFull))
                }
            case .failure(let error):
                self.mainVC?.sendAnalyticsEvent(screenName: screenJoinToMs, eventName: validationInviteQr + "Fail")
                self.mainVC?.presentAlert(with: error)
                self.isCanValidate = true
            }
        }
    }
}
