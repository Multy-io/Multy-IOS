//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
import FirebaseMessaging

private typealias FCMDelegate = DataManager
private typealias UserDefaultsDelegate = DataManager

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
    var savedAddresses = [String: String]()
    
    override init() {
        super.init()
        
        seedWordsArray = coreLibManager.mnemonicAllWords()
        
        savedAddresses = fetchAddressesFromUD()
//        fetchSavedAddresses(completion: { [unowned self] (addresses, error) in
//            if error == nil {
//                if addresses == nil {
//                    self.savedAddresses = SavedAddressesRLM()
//                } else {
//                    self.savedAddresses = addresses!
//                }
//            } else {
//                self.savedAddresses = SavedAddressesRLM()
//            }
//        })
    }
    
    func mapAddressesAndSave(_ contacts: [EPContact]) {
        savedAddresses.removeAll()
        
        for contact in contacts {
            for addressRLM in contact.addresses {
                //check if exist address for another user
                if savedAddresses[addressRLM.address] == nil {
                    savedAddresses[addressRLM.address] = contact.displayName()
                }
            }
        }
        
        saveAddressesToUD(savedAddresses)
    }
    
    func isAddressSaved(_ address: String) -> Bool {
        return savedAddresses[address] != nil
    }
    
    func name(for address: String) -> String {
        return savedAddresses[address] != nil ? savedAddresses[address]! : ""
    }
    
    func getBTCDonationAddress(netType: UInt32) -> String {
        return netType == 0 ? btcMainNetDonationAddress : Constants.DataManager.btcTestnetDonationAddress
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
    
    func makeExchangeFor(blockchainType: BlockchainType) -> Double {
        switch blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            return self.currencyExchange.btcToUSD
        case BLOCKCHAIN_ETHEREUM:
            return self.currencyExchange.ethToUSD
        default: return 1.0
        }
    }
    
    func generateWalletPrimaryKey(currencyID: UInt32, networkID: UInt32, walletID: Int32, inviteCode: String?) -> String {
        let currencyString = String(currencyID).sha3(.sha256)
        let walletString = String(walletID).sha3(.sha256)
        let networkString = String(networkID).sha3(.sha256)
        let inviteCodeString = inviteCode?.sha3(.sha256)
        
        var resultString = "\(currencyString)" + "\(walletString)" + "\(networkString)"
        
        if inviteCodeString != nil {
            resultString += inviteCodeString!
        }
        
        return resultString.sha3(.sha256)
    }
    
    func updateSavedAddresses(_ addresses: [String: String], completion: @escaping(_ error: NSError?) -> ()) {
        savedAddresses = addresses
//        realmManager.updateSavedAddresses(addresses) { [unowned self] (error) in
//            if error == nil {
//                self.savedAddresses.addressesData = addresses.addressesData
//            }
//            completion(error)
//        }
    }
    
    func fetchSavedAddresses(completion: @escaping(_ addresses: SavedAddressesRLM?, _ error: NSError?) -> ()) {
        realmManager.fetchSavedAddresses { (addresses, error) in
            completion(addresses, error)
        }
    }
}

extension UserDefaultsDelegate {
    func getBTCDonationAddressesFromUserDerfaults() -> Dictionary<Int, String> {
        let donationData  = UserDefaults.standard.object(forKey: Constants.UserDefaults.btcDonationAddressesKey) as! Data
        let decodedDonationAddresses = NSKeyedUnarchiver.unarchiveObject(with: donationData) as! Dictionary<Int, String>
        
        return decodedDonationAddresses
    }
    
    func checkIsFirstLaunch() -> Bool {
        if let isFirst = UserDefaults.standard.value(forKey: "isFirstLaunch") {
            return isFirst as! Bool
        } else {
            UserDefaults.standard.set(false, forKey: "isFirstLaunch")
            return true
        }
    }
    
    func checkTermsOfService() -> Bool {
        if let isTerms = UserDefaults.standard.value(forKey: "isTermsAccept") {
            return isTerms as! Bool
        } else {
            //            UserDefaults.standard.set(true, forKey: "isFirstLaunch")
            return false
        }
    }
    
    func isFCMSubscribed() -> Bool {
        if let isAccepted = UserDefaults.standard.value(forKey: "isFCMAccepted") as? Bool {
            return isAccepted
        } else {
            return false
        }
    }
    
    func saveMultisigFactories(_ factoriesInfo: Dictionary<String, String>) {
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: factoriesInfo)
        
        UserDefaults.standard.set(encodedData, forKey: "multisigFactoriesKey")
    }
    
    func multisigFactory(for blockchainType: BlockchainType) -> String? {
        let data = UserDefaults.standard.data(forKey: "multisigFactoriesKey")
        guard data != nil else {
            return nil
        }
        
        let decodedDictionary = NSKeyedUnarchiver.unarchiveObject(with: data!) as? Dictionary<String, String>
        guard decodedDictionary != nil else {
            return nil
        }
        
        switch blockchainType.blockchain {
        case BLOCKCHAIN_ETHEREUM:
            switch Int32(blockchainType.net_type) {
            case ETHEREUM_CHAIN_ID_MAINNET.rawValue:
                return decodedDictionary!["ethmainnet"]
            case ETHEREUM_CHAIN_ID_RINKEBY.rawValue:
                return decodedDictionary!["ethtestnet"]
            default:
                return nil
            }
        default:
            return nil
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
