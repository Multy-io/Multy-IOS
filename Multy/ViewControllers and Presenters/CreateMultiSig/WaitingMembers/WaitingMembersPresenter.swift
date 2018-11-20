//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import UIKit
//import MultyCoreLibrary

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
    let createdMultiSigWallet = UserWalletRLM()
    var estimationInfo: NSDictionary? 
    var feeAmount = BigInt("\(1_000_000_000)") * BigInt("\(5_000_000)")
    var fastGasPriceRate = "1" {
        didSet {
            feeAmount = BigInt(fastGasPriceRate) * BigInt(getEstimation(for: "deployMultisig"))
            if bottomButtonStatus.rawValue == 3 {
                self.viewController!.setupBtnTitle()
            }
        }
    }
    
    func getFeeRate(_ blockchainType: BlockchainType, completion: @escaping (_ feeRateDict: String) -> ()) {
        DataManager.shared.getFeeRate(currencyID: blockchainType.blockchain.rawValue,
                                      networkID: UInt32(blockchainType.net_type),
                                      ethAddress: nil,
                                      completion: { (dict, error) in
                                        print(dict)
                                        if let feeRates = dict!["speeds"] as? NSDictionary, let feeRate = feeRates["Fast"] as? UInt64 {
                                            completion("\(feeRate)")
                                        } else {
                                            //default values
                                            switch blockchainType.blockchain {
                                            case BLOCKCHAIN_BITCOIN:
                                                return completion("10")
                                            case BLOCKCHAIN_ETHEREUM:
                                                return completion("1000000000")
                                            default:
                                                return completion("1")
                                            }
                                        }
        })
    }
    
    func viewControllerViewDidLoad() {
//        inviteCode = makeInviteCode()
//        viewController?.openShareInviteVC()
        updateWallet()
        getFeeRate(BlockchainType.create(wallet: wallet)) { (feeString) in
            self.fastGasPriceRate = feeString
        }
    }
    
    func viewControllerViewWillAppear() {
        //        inviteCode = makeInviteCode()
   //     viewController?.openShareInviteVC()
        updateWallet()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMembersUpdatedNotification(notification:)), name: NSNotification.Name("msMembersUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleWalletDeletedNotification(notification:)), name: NSNotification.Name("msWalletDeleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleWalletUpdatedNotification(notification:)), name: NSNotification.Name("msWalletUpdated"), object: nil)
    }
    
    func viewControllerViewWillDisappear() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msMembersUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msWalletDeleted"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msWalletUpdated"), object: nil)
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
    
    @objc fileprivate func handleWalletDeletedNotification(notification : Notification) {
        let inviteCode = notification.userInfo!["inviteCode"] as! String
        if inviteCode == wallet.multisigWallet?.inviteCode {
            DispatchQueue.main.async {
                if !(self.wallet.multisigWallet?.amICreator)! {
                    self.viewController?.navigationController?.popToRootViewController(animated: true)
                }
            }
        }
    }
    
    @objc fileprivate func handleMembersUpdatedNotification(notification : Notification) {
        let inviteCode = notification.userInfo!["inviteCode"] as! String
        if inviteCode == wallet.multisigWallet?.inviteCode {
            if notification.userInfo!["kickedAddress"] != nil && wallet.multisigWallet?.linkedWalletAddress == notification.userInfo!["kickedAddress"] as! String {
                self.viewController?.navigationController?.popToRootViewController(animated: true)
                return
            }
            
            DispatchQueue.main.async {
                self.updateWallet()
            }
        }
    }
    
    @objc fileprivate func handleWalletUpdatedNotification(notification : Notification) {
        let inviteCode = notification.userInfo!["inviteCode"] as! String
        if inviteCode == wallet.multisigWallet!.inviteCode {
            if inviteCode == wallet.multisigWallet!.inviteCode {
                viewController!.openNewlyCreatedWallet()
                
                return
            }
            
            DispatchQueue.main.async {
                self.updateWallet()
            }
        }
    }
        
    fileprivate func updateWallet() {
        DataManager.shared.getOneWalletVerbose(wallet: wallet) { [unowned self] (wallet, error) in
            DispatchQueue.main.async {
                if wallet != nil {
                    self.wallet = wallet!
                    self.viewController?.updateUI()
                }
            }
        }
    }
    
    func getEstimationInfo(completion: @escaping(_ result: Result<NSDictionary, String>) -> ()) {
        DataManager.shared.estimation(for: "price") { [unowned self] in
            switch $0 {
            case .success(let value):
                self.estimationInfo = value
                break
            case .failure(let error):
                print(error)
            }
            
            completion($0)
        }
    }
    
    func payForMultiSig() {
        DataManager.shared.getWallet(primaryKey: wallet.multisigWallet!.linkedWalletID) { [unowned self] in
            switch $0 {
            case .success(let wallet):
                self.createAndSendMSTransaction(linkedWallet: wallet)
                break;
            case .failure(let errorString):
                print(errorString)
                break;
            }
        }
    }
    
    func getEstimation(for operation: String) -> String {
        let value = self.estimationInfo?[operation] as? NSNumber
        
        let operationPrice = (operation == "priceOfCreation") ? "\(100_000_000_000_000_000)" : "\(5_000_000)"
        
        return value == nil ? operationPrice : "\(value!)"
    }
    
    func createAndSendMSTransaction(linkedWallet: UserWalletRLM) {
        var binData = account!.binaryDataString.createBinaryData()!
        let ownersString = createOwnersString()
        let gasLimitForDeployMS = getEstimation(for: "deployMultisig")
        
        guard estimationInfo != nil else {
            self.viewController?.presentAlert(with: self.viewController?.localize(string: Constants.somethingWentWrongString))
            
            return
        }
        
        let result = DataManager.shared.createMultiSigWallet(binaryData: &binData,
                                                             wallet: linkedWallet,
                                                             creationPriceString: "\(estimationInfo!["priceOfCreation"] as! NSNumber)",
                                                             gasPriceString: fastGasPriceRate,
                                                             gasLimitString: gasLimitForDeployMS,
                                                             owners: ownersString,
                                                             confirmationsCount: UInt32(wallet.multisigWallet!.signaturesRequiredCount))
        if result.isTransactionCorrect {
            let newAddressParams = [
                "walletindex"   : linkedWallet.walletID.intValue,
                "address"       : "",
                "addressindex"  : linkedWallet.addresses.count,
                "transaction"   : result.message,
                "ishd"          : NSNumber(booleanLiteral: false)
                ] as [String : Any]

            let params = [
                "currencyid": linkedWallet.chain,
                "networkid" : linkedWallet.chainType,
                "payload"   : newAddressParams
                ] as [String : Any]

            guard viewController!.presentNoInternetScreen() else {

                return
            }
            
            DataManager.shared.sendHDTransaction(transactionParameters: params) { [unowned self] (dict, error) in
                print("---------\(dict)")
                
                if let code = dict?["code"] as? Int, code == 200 {
                    self.closeVC()
                    self.viewController?.presentAlert(withTitle: self.viewController?.localize(string: Constants.warningString),
                                                      andMessage: self.viewController?.localize(string: Constants.pendingMultisigAlertString))
                } else {
                    if error != nil {
                        self.viewController!.sendAnalyticsEvent(screenName: self.className, eventName: (error! as NSError).userInfo.debugDescription)
                        let errStringFromServer = error?.localizedDescription
                        if errStringFromServer!.range(of: "spend more") != nil {
                            self.viewController?.presentAlert(with: self.viewController?.localize(string: Constants.youTryingSpendMoreThenHaveString))
                        } else {
                            self.viewController?.presentAlert(with: error?.localizedDescription)
                        }
                    } else {
                        self.viewController?.presentAlert(with: self.viewController?.localize(string: Constants.somethingWentWrongString))
                    }
                }
            }
        } else {
            //FIXME: localize
            viewController!.presentAlert(with: result.message)
        }
    }
    
    func closeVC() {
        viewController?.navigationController?.popToRootViewController(animated: true)
    }
    
    func createOwnersString() -> String {
        let ownersString = wallet.multisigWallet!.owners.map { $0.address }.joined(separator: ", ")
        
        return "[\(ownersString)]"
    }
}
