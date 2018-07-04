//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
import FirebaseMessaging

private typealias FCMDelegate = DataManager

class DataManager: NSObject {
    static let shared = DataManager()
    
    let apiManager = ApiManager.shared
    let realmManager = RealmManager.shared
    let socketManager = Socket.shared
    let coreLibManager = CoreLibManager.shared
    
    var seedWordsArray = [String]()
    
    var donationCode = 0
    var btcMainNetDonationAddress = String()
    
    var currencyExchange = CurrencyExchange()
    
    override init() {
        super.init()
        
        seedWordsArray = coreLibManager.mnemonicAllWords()
    }
    
    func getBTCDonationAddress(netType: UInt32) -> String {
        return netType == 0 ? btcMainNetDonationAddress : Constants.DataManager.btcTestnetDonationAddress
    }
    
    func getBTCDonationAddressesFromUserDerfaults() -> Dictionary<Int, String> {
        let donationData  = UserDefaults.standard.object(forKey: Constants.UserDefaults.btcDonationAddressesKey) as! Data
        let decodedDonationAddresses = NSKeyedUnarchiver.unarchiveObject(with: donationData) as! Dictionary<Int, String>
        
        return decodedDonationAddresses
    }
    
    func isWordCorrect(word: String) -> Bool {
        if seedWordsArray.count > 0 {
            return seedWordsArray.contains(word)
        } else {
            return true
        }
    }
    
    func findPrefixes(prefix: String) -> [String] {
        return seedWordsArray.filter{ $0.hasPrefix(prefix) }
    }
    
    func checkIsFirstLaunch() -> Bool {
        if let isFirst = UserDefaults.standard.value(forKey: "isFirstLaunch") {
            return isFirst as! Bool
        } else {
//            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
            return true
        }
    }
    
    func checkTermsOfService() -> Bool {
        if let isTerms = UserDefaults.standard.value(forKey: "isTermsAccept") {
            return isTerms as! Bool
        } else {
            //            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
            return true
        }
    }
    
    func makeExchangeFor(blockchainType: BlockchainType) -> Double {
        switch blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            return self.currencyExchange.btcToUSD
        case BLOCKCHAIN_ETHEREUM:
            return self.currencyExchange.ethToUSD
        default: return 1.0
        }
    }
    
    func generateWalletPrimaryKey(currencyID: UInt32, networkID: UInt32, walletID: UInt32) -> String {
        let currencyString = String(currencyID).sha3(.sha256)
        let walletString = String(walletID).sha3(.sha256)
        let networkString = String(networkID).sha3(.sha256)
        
        return ("\(currencyString)" + "\(walletString) +\(networkString)").sha3(.sha256)
    }
    
    func isFCMSubscribed() -> Bool {
        if let isAccepted = UserDefaults.standard.value(forKey: "isFCMAccepted") as? Bool {
            return isAccepted
        } else {
            return false
        }
    }
    
    
    func createTempWallet(blockchainType: BlockchainType) -> UserWalletRLM {
        let tempWallet = UserWalletRLM()
        tempWallet.chain = NSNumber(value: blockchainType.blockchain.rawValue)
        tempWallet.chainType = NSNumber(value: blockchainType.net_type)
        tempWallet.name = "\(blockchainType.shortName) Wallet with Exchange"
        return tempWallet
    }
    
    
    func createWallet(blockchianType: BlockchainType, completion: @escaping (_ answer: String?,_ error: Error?) -> ()) {
        getAccount { (account, err) in
            var binData : BinaryData = account!.binaryDataString.createBinaryData()!
            let createdWallet = UserWalletRLM()
            //MARK: topIndex
            let currencyID = blockchianType.blockchain.rawValue
            let networkID = blockchianType.net_type
            var currentTopIndex = account!.topIndexes.filter("currencyID = \(currencyID) AND networkID == \(networkID)").first
            
            if currentTopIndex == nil {
                //            mainVC?.presentAlert(with: "TopIndex error data!")
                currentTopIndex = TopIndexRLM.createDefaultIndex(currencyID: NSNumber(value: currencyID), networkID: NSNumber(value: networkID), topIndex: NSNumber(value: 0))
            }
            
            let dict = DataManager.shared.createNewWallet(for: &binData, blockchain: blockchianType, walletID: currentTopIndex!.topIndex.uint32Value)
            
            createdWallet.chain = NSNumber(value: currencyID)
            createdWallet.chainType = NSNumber(value: networkID)
            createdWallet.name = "\(blockchianType.shortName) Wallet with Exchange"
            createdWallet.walletID = NSNumber(value: dict!["walletID"] as! UInt32)
            createdWallet.addressID = NSNumber(value: dict!["addressID"] as! UInt32)
            createdWallet.address = dict!["address"] as! String
            
            if createdWallet.blockchainType.blockchain == BLOCKCHAIN_ETHEREUM {
                createdWallet.ethWallet = ETHWallet()
                createdWallet.ethWallet?.balance = "0"
                createdWallet.ethWallet?.nonce = NSNumber(value: 0)
                createdWallet.ethWallet?.pendingWeiAmountString = "0"
            }
            
            let params = [
                "currencyID"    : currencyID,
                "networkID"     : networkID,
                "address"       : createdWallet.address,
                "addressIndex"  : createdWallet.addressID,
                "walletIndex"   : createdWallet.walletID,
                "walletName"    : createdWallet.name
                ] as [String : Any]
            
            DataManager.shared.addWallet(params: params) { (dict, error) in
                if error == nil {
                    //                self.assetsVC!.sendAnalyticsEvent(screenName: screenCreateWallet, eventName: cancelTap)
                    completion("ok", nil)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }
}

extension FCMDelegate {
    func subscribeToFirebaseMessaging() {
        getAccount { (acc, err) in
            Messaging.messaging().subscribe(toTopic: "TransactionUpdate-\(acc?.userID ?? "userId is empty")")
            UserDefaults.standard.set(true, forKey: "isFCMAccepted")
        }
    }
    
    func subscribeToFirebaseMessaging(completion: @escaping (_ isOperationSuccessful: Bool) -> ()) {
        getAccount { (acc, err) in
            Messaging.messaging().subscribe(toTopic: "TransactionUpdate-\(acc?.userID ?? "userId is empty")") { (error) in
                let boolValue = error != nil
                UserDefaults.standard.set(boolValue, forKey: "isFCMAccepted")
                completion(boolValue)
            }
        }
    }
    
    func unsubscribeToFirebaseMessaging() {
        getAccount { (acc, err) in
            Messaging.messaging().unsubscribe(fromTopic: "TransactionUpdate-\(acc?.userID ?? "userId is empty")")
            UserDefaults.standard.set(false, forKey: "isFCMAccepted")
        }
    }
    
    func unsubscribeToFirebaseMessaging(completion: @escaping (_ isOperationSuccessful: Bool) -> ()) {
        getAccount { (acc, err) in
            Messaging.messaging().unsubscribe(fromTopic: "TransactionUpdate-\(acc?.userID ?? "userId is empty")") { (error) in
                let boolValue = error != nil
                UserDefaults.standard.set(boolValue, forKey: "isFCMAccepted")
                completion(boolValue)
            }
        }
    }
}
