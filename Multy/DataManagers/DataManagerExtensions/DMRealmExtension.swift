//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift
import Realm

extension DataManager {
    func writeSeedPhrase(_ seedPhrase : String, completion: @escaping (_ error: NSError?) -> ()) {
        realmManager.writeSeedPhrase(seedPhrase) { (error) in
            completion(error)
        }
    }
    
    func deleteSeedPhrase(completion: @escaping (_ error: NSError?) -> ()) {
        realmManager.deleteSeedPhrase { (error) in
            completion(error)
        }
    }
    
    func getSeedPhrase(completion: @escaping (_ seedPhrase: String?, _ error: NSError?) -> ()) {
        realmManager.getSeedPhrase { (seedPhrase, error) in
            completion(seedPhrase, error)
        }
    }
    
    func createWallet(from walletDict: Dictionary<String, Any>,
                      completion: @escaping (_ wallet: UserWalletRLM?, _ error: NSError?) -> ()) {
        realmManager.createWallet(walletDict) { (wallet, error) in
            completion(wallet, error)
        }
    }
    
    func getExchangePrice(completion: @escaping (_ exchangePrice : ExchangePriceRLM?, _ error: NSError?) -> ())  {
        realmManager.getExchangePrice { (exchangePrice, error) in
            completion(exchangePrice, error)
        }
    }
    
    func getAccount(completion: @escaping (_ acc: AccountRLM?, _ error: NSError?) -> ()) {
        realmManager.getAccount { (acc, err) in
            completion(acc, err)
        }
    }
    
    func isAccountExists(completion: @escaping (_ isExists: Bool) -> ()) {
        realmManager.getAccount { (acc, err) in
            completion(acc != nil)
        }
    }

    
    func updateAccount(_ accountDict: NSDictionary, completion: @escaping (_ account : AccountRLM?, _ error: NSError?) -> ()) {
        realmManager.updateAccount(accountDict) { (account, error) in
            completion(account, error)
        }
    }
    
    func isThereDefaultRealmFile() -> Bool {
        let fileManager = FileManager.default
        let realmPath = RLMRealmPathForFile("default.realm")
        
        let url = try! fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: URL(string: realmPath), create: false)
        if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.absoluteString.hasSuffix("default.realm") {
                    return true
                }
            }
            
            return false
        }
        
        return false
    }
    
    func clearDB(completion: @escaping (_ error: NSError?) -> ()) {
        let fileManager = FileManager.default
        let config = realmManager.config!
        
        autoreleasepool {
            do {
                let oldRealm = try Realm(configuration: config)
                oldRealm.invalidate()
                
                let url = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: config.fileURL!, create: false)
                if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil) {
                    while let fileURL = enumerator.nextObject() as? URL {
                        try fileManager.removeItem(at: fileURL)
                    }
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        }
        
        completion(nil)
    }
    
    func finishRealmSession() {
        realmManager.finishRealmSession()
    }
    
    func fetchSpendableOutput(wallet: UserWalletRLM) -> [SpendableOutputRLM] {
        return realmManager.spendableOutput(wallet: wallet)
    }
    
    func greedySubSet(outputs: [SpendableOutputRLM], threshold: UInt64) -> [SpendableOutputRLM] {
        return realmManager.greedySubSet(outputs: outputs, threshold: threshold)
    }
    
    func spendableOutputSum(outputs: [SpendableOutputRLM]) -> UInt64 {
        return realmManager.spendableOutputSum(outputs: outputs)
    }
    
    func updateToken(_ token: String) {
        let tokenData = ["token" : token] as NSDictionary;
        apiManager.token = token
        realmManager.updateAccount(tokenData) { (_, _) in }
    }
    
    func getWallet(primaryKey: String, completion: @escaping(_ result: Result<UserWalletRLM, String>) -> ()) {
        realmManager.getWallet(primaryKey: primaryKey) { completion($0) }
    }
    
    func update(wallet: UserWalletRLM, impPK: String, impPubK: String) {
        realmManager.updateImportedWallet(wallet: wallet, impPK: impPK, impPubK: impPubK)
    }
}
