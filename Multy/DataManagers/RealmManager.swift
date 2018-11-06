//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
import Realm
//import MultyCoreLibrary

private typealias RealmMigrationManager = RealmManager
private typealias RecentAddressManager = RealmManager
private typealias CurrencyExchangeManager = RealmManager
private typealias WalletManager = RealmManager
private typealias LegacyCodeManager = RealmManager
private typealias SeedPhraseManager = RealmManager
private typealias TokensManager = RealmManager

class RealmManager: NSObject {
    static let shared = RealmManager()
    
    private var realm : Realm? = nil
    let schemaVersion : UInt64 = 32
    
    var account: AccountRLM?
    var config: Realm.Configuration?
    
    var erc20Tokens = Dictionary<String, TokenRLM>()
    
    var schemaversion : UInt64 {
        return realm!.configuration.schemaVersion
    }
    
    private override init() {
        super.init()
    }
    
    public func finishRealmSession() {
        realm = nil
    }
    
    func getCurrentRealmName(_ pass: Data) -> String {
        if DataManager.shared.isThereDefaultRealmFile() {
            return "default.realm"
        } else {
            let hash = pass.bytes.sha3(.keccak512).data.hexEncodedString()
            let nameSuffix = String(hash.suffix(8))
            
            return  "default_" + nameSuffix + ".realm"
        }
    }
    
    public func getRealm(completion: @escaping (_ realm: Realm?, _ error: NSError?) -> ()) {
        if realm != nil {
            completion(realm!, nil)
            
            return
        }
        
        UserPreferences.shared.getAndDecryptDatabasePassword { [unowned self] (pass, error) in
            guard pass != nil else {
                completion(nil, nil)
                
                return
            }
            
            let realmName = self.getCurrentRealmName(pass!)
            
            let realmConfig = Realm.Configuration(fileURL: URL(fileURLWithPath: RLMRealmPathForFile(realmName), isDirectory: false),
                                                  encryptionKey: pass,
                                                  schemaVersion: self.schemaVersion,
                                                  migrationBlock: { [unowned self] (migration, oldSchemaVersion) in
                                                    if oldSchemaVersion < 7 {
                                                        self.migrateFrom6To7(with: migration)
                                                    }
                                                    if oldSchemaVersion < 8 {
                                                        self.migrateFrom7To8(with: migration)
                                                    }
                                                    if oldSchemaVersion < 9 {
                                                        self.migrateFrom8To9(with: migration)
                                                    }
                                                    if oldSchemaVersion < 10 {
                                                        self.migrateFrom9To10(with: migration)
                                                    }
                                                    if oldSchemaVersion < 11 {
                                                        self.migrateFrom10To11(with: migration)
                                                    }
                                                    if oldSchemaVersion < 12 {
                                                        self.migrateFrom11To12(with: migration)
                                                    }
                                                    if oldSchemaVersion < 13 {
                                                        self.migrateFrom12To13(with: migration)
                                                    }
                                                    if oldSchemaVersion < 14 {
                                                        self.migrateFrom13To14(with: migration)
                                                    }
                                                    if oldSchemaVersion < 15 {
                                                        self.migrateFrom14To15(with: migration)
                                                    }
                                                    if oldSchemaVersion < 16 {
                                                        self.migrateFrom15To16(with: migration)
                                                    }
                                                    if oldSchemaVersion < 17 {
                                                        self.migrateFrom16To17(with: migration)
                                                    }
                                                    if oldSchemaVersion < 18 {
                                                        self.migrateFrom17To18(with: migration)
                                                    }
                                                    if oldSchemaVersion < 19 {
                                                        self.migrateFrom18To19(with: migration)
                                                    }
                                                    if oldSchemaVersion < 20 {
                                                        self.migrateFrom19To20(with: migration)
                                                    }
                                                    if oldSchemaVersion < 21 {
                                                        self.migrateFrom20To21(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 22 {
                                                        self.migrateFrom21To22(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 23 {
                                                        self.migrateFrom22To23(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 24 {
                                                        self.migrateFrom23To24(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 25 {
                                                        self.migrateFrom24To25(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 26 {
                                                        self.migrateFrom25To26(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 27 {
                                                        self.migrateFrom26To27(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 28 {
                                                        self.migrateFrom27To28(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 29 {
                                                        self.migrateFrom28To29(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 30 {
                                                        self.migrateFrom29To30(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 31 {
                                                        self.migrateFrom30To31(with: migration)
                                                    }
                                                    if oldSchemaVersion <= 31 {
                                                        self.migrateFrom31To32(with: migration)
                                                    }
            })
            
            self.config = realmConfig
            
            do {
                let realm = try Realm(configuration: self.config!)
                self.realm = realm
                
                
                completion(realm, nil)
            } catch let error as NSError {
                try! FileManager.default.removeItem(at: Realm.Configuration.defaultConfiguration.fileURL!)
                completion(nil, error)
                fatalError("Error opening Realm: \(error)")
            }
        }
    }
    
    public func updateAccount(_ accountDict: NSDictionary, completion: @escaping (_ account : AccountRLM?, _ error: NSError?) -> ()) {
        getRealm { [weak self] (realmOpt, error) in
            if let realm = realmOpt {
                let account = realm.object(ofType: AccountRLM.self, forPrimaryKey: 1)
                
                //avoid creating account
                if account == nil && accountDict["token"] != nil && accountDict.allKeys.count == 1 {
                    completion(nil, nil)
                    
                    return
                }
                
                try! realm.write {
                    //replace old value if exists
                    let accountRLM = account == nil ? AccountRLM() : account!
                    
                    if accountDict["expire"] != nil {
                        accountRLM.expireDateString = accountDict["expire"] as! String
                    }
                    
                    if accountDict["token"] != nil {
                        accountRLM.token = accountDict["token"] as! String
                    }
                    
                    if accountDict["userID"] != nil {
                        accountRLM.userID = accountDict["userID"] as! String
                    }
                    
                    if accountDict["deviceID"] != nil {
                        accountRLM.deviceID = accountDict["deviceID"] as! String
                    }
                    
                    if accountDict["pushToken"] != nil {
                        accountRLM.pushToken = accountDict["pushToken"] as! String
                    }
                    
                    if accountDict["seedPhrase"] != nil {
                        accountRLM.seedPhrase = accountDict["seedPhrase"] as! String
                    }
                    
                    if accountDict["backupSeedPhrase"] != nil {
                        accountRLM.backupSeedPhrase = accountDict["backupSeedPhrase"] as! String
                    }
                    
                    if accountDict["binaryData"] != nil {
                        accountRLM.binaryDataString = accountDict["binaryData"] as! String
                    }
                    
                    if accountDict["topindexes"] != nil {
                        let newTopIndexes = TopIndexRLM.initWithArray(indexesArray: accountDict["topindexes"] as! NSArray)
                        accountRLM.topIndexes.removeAll()
                        self!.deleteTopIndexes(from: realm)
                        for newIndex in newTopIndexes {
                            accountRLM.topIndexes.append(newIndex)
                        }
                    }
                    
                    if accountDict["wallets"] != nil && !(accountDict["wallets"] is NSNull) {
                        let walletsList = accountDict["wallets"] as! List<UserWalletRLM>
                        
                        for wallet in walletsList {
                            let walletFromDB = realm.object(ofType: UserWalletRLM.self, forPrimaryKey: wallet.id)
                            
                            if walletFromDB != nil {
                                realm.add(wallet, update: true)
                            } else {
                                accountRLM.wallets.append(wallet)
                            }
                        }
                        
                        accountRLM.walletCount = NSNumber(value: accountRLM.wallets.count)
                    }
                    
                    realm.add(accountRLM, update: true)
                    self!.account = accountRLM
                    
                    completion(accountRLM, nil)
                    
                    #if DEBUG
                    print("Successful writing account: \(accountRLM)")
                    #endif
                }
            } else {
                print("Error fetching realm:\(#function)")
                completion(nil, nil)
            }
        }
    }
    
    public func updateExchangePrice(_ ratesDict: NSDictionary, completion: @escaping (_ exchangePrice : ExchangePriceRLM?, _ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let exchange = ExchangePriceRLM.initWithInfo(info: ratesDict)
                
                try! realm.write {
                    realm.add(exchange, update: true)

                    completion(exchange, nil)

                    print("Successful writing exchange price")
                }
            } else {
                print("Error fetching realm:\(#function)")
                completion(nil, nil)
            }
        }
    }
    
    public func getExchangePrice(completion: @escaping (_ exchangePrice : ExchangePriceRLM?, _ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let prices = realm.object(ofType: ExchangePriceRLM.self, forPrimaryKey: 1)
                
                if prices != nil {
                    completion(prices, nil)
                } else {
                    completion(nil, nil)
                }
            } else {
                print("Error fetching realm:\(#function)")
                completion(nil, nil)
            }
        }
    }
    
    public func getAccount(completion: @escaping (_ account: AccountRLM?, _ error: NSError?) -> ()) {
        getRealm { [weak self] (realmOpt, err) in
            if let realm = realmOpt {
                let acc = realm.object(ofType: AccountRLM.self, forPrimaryKey: 1)
                if acc != nil {
                    self!.account = acc!
                    completion(acc!, nil)
                } else {
                    completion(nil, nil)
                }
            } else {
                print("Err from realm GetAcctount:\(#function)")
                completion(nil,nil)
            }
        }
    }
    
    public func clearRealm(completion: @escaping(_ ok: String?, _ error: Error?) -> ()) {
        getRealm { (realmOpt, err) in
            if err != nil {
                completion(nil, err)
                return
            }
            if let realm = realmOpt {
                try! realm.write {
                    
                    let resultSeedPhrase = realm.objects(SeedPhraseRLM.self)
                    realm.delete(resultSeedPhrase)
                    
                    let resultAccount = realm.objects(AccountRLM.self)
                    realm.delete(resultAccount)
                    
                    let resultTopIndex = realm.objects(TopIndexRLM.self)
                    realm.delete(resultTopIndex)
                    
                    let resultHistory = realm.objects(HistoryRLM.self)
                    realm.delete(resultHistory)
                    
                    let resultTxHistory = realm.objects(TxHistoryRLM.self)
                    realm.delete(resultTxHistory)
                    
                    let resultExchange = realm.objects(ExchangePriceRLM.self)
                    realm.delete(resultExchange)
                    let resultAddress = realm.objects(AddressRLM.self)
                    realm.delete(resultAddress)
                    let resultWallet = realm.objects(UserWalletRLM.self)
                    realm.delete(resultWallet)
                    let resultOutput = realm.objects(SpendableOutputRLM.self)
                    realm.delete(resultOutput)
                    let resultRecent = realm.objects(RecentAddressesRLM.self)
                    realm.delete(resultRecent)
                    let resultExchanges = realm.objects(StockExchangeRateRLM.self)
                    realm.delete(resultExchanges)
                    let resultCurrency = realm.objects(CurrencyExchangeRLM.self)
                    realm.delete(resultCurrency)
                    let resultContacts = realm.objects(ContactRLM.self)
                    realm.delete(resultContacts)
                    
                    realm.deleteAll()
                    
                    completion("ok", nil)
                }
            }
            
        }
        
        account = nil
    }
    
    func getTransactionHistoryBy(walletIndex: Int, completion: @escaping(_ arrOfHist: Results<HistoryRLM>?) -> ()) {
        getRealm { (realmOpt, err) in
            if let realm = realmOpt {
                let allHistoryObjects = realm.objects(HistoryRLM.self).filter("walletIndex = \(walletIndex)")
                if !allHistoryObjects.isEmpty {
                    completion(allHistoryObjects)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    func deleteTopIndexes(from realm: Realm) {
        let topIndexObjects = realm.objects(TopIndexRLM.self)
        realm.delete(topIndexObjects)
    }

    func deleteAddressesAndSpendableInfo(_ addresses: List<AddressRLM>,  from realm: Realm) {
        for address in addresses {
            realm.delete(address.spendableOutput)
            realm.delete(address)
        }
    }
}

extension SeedPhraseManager {
    public func getSeedPhrase(completion: @escaping (_ seedPhrase: String?, _ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let seedPhraseOpt = realm.object(ofType: SeedPhraseRLM.self, forPrimaryKey: 1)
                
                if seedPhraseOpt == nil {
                    completion(nil, nil)
                } else {
                    completion(seedPhraseOpt!.seedString, nil)
                }
            } else {
                print("Error fetching realm:\(#function)")
                completion(nil, nil)
            }
        }
    }
    
    public func writeSeedPhrase(_ seedPhrase: String, completion: @escaping (_ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let seedPhraseOpt = realm.object(ofType: SeedPhraseRLM.self, forPrimaryKey: 1)
                
                try! realm.write {
                    //replace old value if exists
                    let seedRLM = seedPhraseOpt == nil ? SeedPhraseRLM() : seedPhraseOpt!
                    seedRLM.seedString = seedPhrase
                    
                    realm.add(seedRLM, update: true)
                    print("Successful writing seed phrase")
                }
            } else {
                print("Error fetching realm:\(#function)")
            }
        }
        
    }
    
    public func deleteSeedPhrase(completion: @escaping (_ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let seedPhraseOpt = realm.object(ofType: SeedPhraseRLM.self, forPrimaryKey: 1)
                
                if let seedPhrase = seedPhraseOpt {
                    try! realm.write {
                        realm.delete(seedPhrase)
                        
                        completion(nil)
                        print("Successful writing seed phrase")
                    }
                } else {
                    completion(NSError())
                    print("Error fetching seedPhrase")
                }
            } else {
                completion(NSError())
                print("Error fetching realm")
            }
        }
    }
    
    public func clearSeedPhraseInAcc() {
        getRealm { (realmOpt, err) in
            if let realm = realmOpt {
                let acc = realm.object(ofType: AccountRLM.self, forPrimaryKey: 1)
                try! realm.write {
                    acc?.seedPhrase = ""
                    print("Seed phrase was deleted from db by realm Manager")
                }
            }
        }
    }
}

extension WalletManager {
    public func createWallet(_ walletDict: Dictionary<String, Any>, completion: @escaping (_ account : UserWalletRLM?, _ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let wallet = UserWalletRLM.initWithInfo(walletInfo: NSDictionary(dictionary: walletDict))
                
                try! realm.write {
                    realm.add(wallet, update: true)
                    
                    completion(wallet, nil)
                    
                    print("Successful writing wallet")
                }
            } else {
                print("Error fetching realm:\(#function)")
                completion(nil, nil)
            }
        }
    }
    
    public func createOrUpdateAccount(accountInfo: NSArray, completion: @escaping(_ account: AccountRLM?, _ error: NSError?)->()) {
        getRealm { [weak self] (realmOpt, err) in
            guard let realm = realmOpt else {
                completion(nil, nil)
                
                return
            }
            
            let account = realm.object(ofType: AccountRLM.self, forPrimaryKey: 1)
            
            guard account != nil else {
                completion(nil, nil)
                
                return
            }
            
            let accountWallets = account!.wallets
            let newWallets = List<UserWalletRLM>()
            
            for wallet in accountInfo {
                let wallet = wallet as! NSDictionary
                let walletID = wallet["WalletIndex"] != nil ? wallet["WalletIndex"] : wallet["walletindex"]
                
                let modifiedWallet = accountWallets.filter("walletID = \(walletID)").first
                
                try! realm.write {
                    //                    if modifiedWallet != nil {
                    //                        modifiedWallet!.addresses = wallet.addresses
                    //                        newWallets.append(modifiedWallet!)
                    //                    } else {
                    //                        newWallets.append(wallet)
                    //                    }
                }
            }
            
            try! realm.write {
                account!.wallets.removeAll()
                for wallet in newWallets {
                    account!.wallets.append(wallet)
                    
                    account!.wallets.last!.addresses.removeAll()
                    for address in wallet.addresses {
                        account!.wallets.last!.addresses.append(address)
                        
                        account!.wallets.last!.addresses.last!.spendableOutput.removeAll()
                        for ouput in address.spendableOutput {
                            account?.wallets.last!.addresses.last!.spendableOutput.append(ouput)
                        }
                    }
                }
                
                self!.account = account
                
                completion(account, nil)
            }
        }
    }
    
    public func updateImportedWalletsInAcc(arrOfWallets: List<UserWalletRLM>, completion: @escaping(_ account: AccountRLM?, _ error: NSError?)->()) {
        getRealm { [weak self] (realmOpt, err) in
            if let realm = realmOpt {
                let acc = realm.object(ofType: AccountRLM.self, forPrimaryKey: 1)
                if acc != nil {
                    let accWallets = acc!.wallets
                    
                    for wallet in arrOfWallets {
                        let modifiedWallet = accWallets.filter {$0.id == wallet.id}.first
                        
                        try! realm.write {
                            if modifiedWallet != nil {
                                modifiedWallet?.importedPublicKey = wallet.importedPublicKey
                                modifiedWallet!.importedPrivateKey = wallet.importedPrivateKey
                                
                                //FIXME: check brokenState
                                modifiedWallet?.brokenState = wallet.brokenState
                            }
                        }
                    }
                    
                    completion(acc, nil)
                } else {
                    completion(nil, err)
                }
            }
        }
    }
    
    public func updateWalletsInAcc(arrOfWallets: List<UserWalletRLM>, completion: @escaping(_ account: AccountRLM?, _ error: NSError?)->()) {
        getRealm { [weak self] (realmOpt, err) in
            if let realm = realmOpt {
                let acc = realm.object(ofType: AccountRLM.self, forPrimaryKey: 1)
                if acc != nil {
                    let accWallets = acc!.wallets
                    let newWallets = List<UserWalletRLM>()
                    
                    for wallet in arrOfWallets {
                        let modifiedWallet = accWallets.filter {$0.id == wallet.id}.first
                        
                        try! realm.write {
                            if modifiedWallet != nil {
                                modifiedWallet!.name =              wallet.name
                                modifiedWallet!.addresses =         wallet.addresses
                                modifiedWallet!.isTherePendingTx =  wallet.isTherePendingTx
                                modifiedWallet!.btcWallet =         wallet.btcWallet
                                
                                let delETH = modifiedWallet?.ethWallet
                                let delM = modifiedWallet?.multisigWallet
                                
                                modifiedWallet?.ethWallet       = wallet.ethWallet
                                modifiedWallet!.multisigWallet  = wallet.multisigWallet
                                
                                if delETH != nil {
                                    realm.delete(delETH!.erc20Tokens)
                                    realm.delete(delETH!)
                                }
                                
                                if delM != nil {
                                    realm.delete(delM!.owners)
                                    realm.delete(delM!)
                                }

                                modifiedWallet?.lastActivityTimestamp = wallet.lastActivityTimestamp
                                modifiedWallet?.isSyncing =         wallet.isSyncing
                                modifiedWallet?.brokenState =       wallet.brokenState
                                
                                newWallets.append(modifiedWallet!)
                            } else {
                                newWallets.append(wallet)
                            }
                        }
                    }
                    
                    try! realm.write {
                        self!.deleteNotUsedMSWalletFromDB(realm: realm, newWallets: newWallets)
                        for wallet in newWallets {
                            acc!.wallets.append(wallet)
                            
                            self!.deleteAddressesAndSpendableInfo(acc!.wallets.last!.addresses, from: realm)
                            
                            acc!.wallets.last!.addresses.removeAll()
                            
                            //MARK: CHECK THIS    deleting addresses    Check addressID and delete existing
                            for address in wallet.addresses {
                                acc!.wallets.last!.addresses.append(address)
                            }
                        }
                        
                        completion(acc, nil)
                    }
                } else {
                    completion(nil, err)
                }
            }
        }
    }
    
    func deleteNotUsedMSWalletFromDB(realm: Realm, newWallets: List<UserWalletRLM>) {
        for wallet in newWallets {
            let walletFromDB = realm.object(ofType: UserWalletRLM.self, forPrimaryKey: wallet.id)
            if walletFromDB != nil && account!.wallets.contains(walletFromDB!) == false {
                deleteWallet(wallet, realm: realm)
            }
        }
        account!.wallets.removeAll()
    }
    
    func getWallet(walletID: NSNumber, completion: @escaping(_ wallet: UserWalletRLM?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let primaryKey = DataManager.shared.generateWalletPrimaryKey(currencyID: 0, networkID: 0, walletID: walletID.int32Value)
                let wallet = realm.object(ofType: UserWalletRLM.self, forPrimaryKey: primaryKey)
                
                completion(wallet)
            } else {
                completion(nil)
            }
        }
    }
    
    func getWallet(primaryKey: String, completion: @escaping(_ result: Result<UserWalletRLM, String>) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let wallet = realm.object(ofType: UserWalletRLM.self, forPrimaryKey: primaryKey)
                
                if wallet == nil {
                    completion(Result.failure("Wallet is missing"))
                } else {
                    completion(Result.success(wallet!))
                }
            } else {
                completion(Result.failure("Cannot get realm"))
            }
        }
    }
    
    func getAllWallets(completion: @escaping(_ wallets: [UserWalletRLM]?,_ error: Error?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let wallets = realm.objects(UserWalletRLM.self)
                completion(Array(wallets), nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    func updateImportedWallet(wallet: UserWalletRLM, impPK: String, impPubK: String) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                try! realm.write {
                    wallet.importedPublicKey = impPubK
                    wallet.importedPrivateKey = impPK
                    realm.add(wallet, update: true)
                }
            }
        }
    }
    
    func spendableOutput(addresses: List<AddressRLM>) -> [SpendableOutputRLM] {
        let ouputs = List<SpendableOutputRLM>()
        
        for address in addresses {
            //add checking output (in/out)
            
            for out in address.spendableOutput {
                ouputs.append(out)
            }
        }
        
        let results = ouputs .sorted(by: { (out1, out2) -> Bool in
            out1.transactionOutAmount.uint64Value > out2.transactionOutAmount.int64Value
        })
        
        return results
    }
    
//    func fetchAddressesForWalllet(walletID: NSNumber, completion: @escaping(_ : [String]?) -> ()) {
//        getWallet(walletID: walletID) { (wallet) in
//            if wallet != nil {
//                var addresses = [String]()
//                wallet!.addresses.forEach({ addresses.append($0.address) })
//                completion(addresses)
//            } else {
//                completion(nil)
//            }
//        }
//    }
    
    func fetchBTCWallets(isTestNet: Bool, completion: @escaping(_ wallets: [UserWalletRLM]?) -> ()) {
        getRealm { (realmOpt, err) in
            if let realm = realmOpt {
                let wallets = realm.objects(UserWalletRLM.self).filter("chainType = \(isTestNet.intValue) AND chain = \(BLOCKCHAIN_BITCOIN.rawValue)")
                let walletsArr = Array(wallets.sorted(by: {$0.availableSumInCrypto > $1.availableSumInCrypto}))
                
                completion(walletsArr)
            }
        }
    }

    func saveHistoryForWallet(historyArr: List<HistoryRLM>, completion: @escaping(_ historyArr: List<HistoryRLM>?) -> ()) {
        getRealm { (realmOpt, err) in
            if let realm = realmOpt {
                try! realm.write {
                    let oldHistoryObjects = realm.objects(HistoryRLM.self)
                    
                    for obj in historyArr {
                        //add checking for repeated tx and updated status
                        let repeatedObj = oldHistoryObjects.filter("txHash = \(obj.txHash)").first
                        if repeatedObj != nil {
                            realm.add(obj, update: true)
                        } else {
                            realm.add(obj, update: true)
                        }
                    }
                    completion(historyArr)
                }
            } else {
                print("Err from realm GetAcctount:\(#function)")
                completion(nil)
            }
        }
    }
    
    func renewCustomWallets(in wallet: UserWalletRLM, from newWallet: UserWalletRLM, for realm: Realm) {
        if wallet.ethWallet != nil {
            realm.delete(wallet.ethWallet!)
        }
        
        if wallet.btcWallet != nil {
            realm.delete(wallet.btcWallet!)
        }
        
        if newWallet.btcWallet != nil {
            realm.add(newWallet.btcWallet!)
        }
        
        if newWallet.ethWallet != nil {
            realm.add(newWallet.ethWallet!)
        }
        
        wallet.ethWallet = newWallet.ethWallet
        wallet.btcWallet = newWallet.btcWallet
    }
    
    func deleteWallet(_ wallet: UserWalletRLM, completion: @escaping(_ account: AccountRLM?) -> ()) {
        //FIXME: only for non-multisig wallets
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let account = realm.object(ofType: AccountRLM.self, forPrimaryKey: 1)
                let walletToDelete = realm.object(ofType: UserWalletRLM.self, forPrimaryKey: wallet.id)
                
                guard account != nil && walletToDelete != nil else {
                    completion(nil)
                    
                    return
                }
                
                let index = account!.wallets.index(where: { $0.id == walletToDelete?.id })
                
                if index != nil {
                    try! realm.write {
                        if walletToDelete!.btcWallet != nil {
                            realm.delete(walletToDelete!.btcWallet!)
                        }
                        
                        if walletToDelete!.ethWallet != nil {
                            realm.delete(walletToDelete!.ethWallet!)
                        }
                        
                        
                        if walletToDelete!.multisigWallet != nil {
                            walletToDelete?.multisigWallet?.owners.forEach { realm.delete($0) }
                            
                            realm.delete(walletToDelete!.multisigWallet!)
                        }
                        
                        account!.wallets.remove(at: index!)
                        realm.delete(walletToDelete!)
                    }
                }
                
                completion(account!)
            } else {
                completion(nil)
            }
        }
    }
    
    
    func deleteWallet(_ wallet: UserWalletRLM, realm: Realm) {
        //FIXME: only for non-multisig wallets
        let walletToDelete = realm.object(ofType: UserWalletRLM.self, forPrimaryKey: wallet.id)
        
        if walletToDelete!.btcWallet != nil {
            realm.delete(walletToDelete!.btcWallet!)
        }
        
        if walletToDelete!.ethWallet != nil {
            realm.delete(walletToDelete!.ethWallet!)
        }
        
        if walletToDelete!.multisigWallet != nil {
            walletToDelete?.multisigWallet?.owners.forEach { realm.delete($0) }
            
            realm.delete(walletToDelete!.multisigWallet!)
        }
        
        realm.delete(walletToDelete!)
    }
    
//    func fetchAddressesForWalllet(walletID: NSNumber, completion: @escaping(_ : [String]?) -> ()) {
//        getWallet(walletID: walletID) { (wallet) in
//            if wallet != nil {
//                var addresses = [String]()
//                wallet!.addresses.forEach({ addresses.append($0.address) })
//                completion(addresses)
//            } else {
//                completion(nil)
//            }
//        }
//    }
}

extension CurrencyExchangeManager {
    func updateCurrencyExchangeRLM(curExchange: CurrencyExchange) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                //                let currencyExchange = realm.object(ofType: CurrencyExchangeRLM.self, forPrimaryKey: 1)
                let curRlm = CurrencyExchangeRLM()
                curRlm.createCurrencyExchange(currencyExchange: curExchange)
                try! realm.write {
                    //                    curRlm.btcToUSD = DataManager.shared.currencyExchange.btcToUSD
                    //                    curRlm.btcToUSD = DataManager.shared.currencyExchange.ethToUSD
                    realm.add(curRlm, update: true)
                }
            } else {
                print("Error fetching realm:\(#function)")
            }
        }
    }
    
    func fetchCurrencyExchange(completion: @escaping(_ curExhange: CurrencyExchangeRLM?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let currencyExchange = realm.object(ofType: CurrencyExchangeRLM.self, forPrimaryKey: 1)
                completion(currencyExchange)
            } else {
                print("Error fetching realm:\(#function)")
                completion(nil)
            }
        }
    }
}

extension RecentAddressManager {
    func writeOrUpdateRecentAddress(blockchainType: BlockchainType, address: String, date: Date) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                try! realm.write {
                    if let recentAddress = realm.object(ofType: RecentAddressesRLM.self, forPrimaryKey: address) {
                        recentAddress.lastActionDate = date
                        realm.add(recentAddress, update: true)
                    } else {
                        let newRecentAddress = RecentAddressesRLM.createRecentAddress(blockchainType: blockchainType, address: address, date: date)
                        realm.add(newRecentAddress, update: false)
                    }
                }
            }
        }
    }
    
    func getRecentAddresses(for chain: UInt32?, netType: Int?, completion: @escaping (_ addresses: Results<RecentAddressesRLM>?, _ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                if chain != nil && netType != nil {
                    let addr = realm.objects(RecentAddressesRLM.self).filter("blockchain = \(chain!)").filter("blockchainNetType = \(netType!)").sorted(byKeyPath: "lastActionDate", ascending: false)
                    completion(addr, nil)
                } else {
                    let addr = realm.objects(RecentAddressesRLM.self).sorted(byKeyPath: "lastActionDate", ascending: false)
                    completion(addr, nil)
                }
            } else {
                completion(nil, error)
            }
        }
    }
    
    func updateSavedAddresses(_ addresses: SavedAddressesRLM, completion: @escaping(_ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                let addressesRLM = realm.objects(SavedAddressesRLM.self).first
                
                try! realm.write {
                    if addressesRLM == nil {
                        realm.add(addresses)
                    } else {
                        addressesRLM!.addressesData = addresses.addressesData
                    }
                }
            } else {
                completion(error)
            }
        }
    }
    
    func fetchSavedAddresses(completion: @escaping(_ addresses: SavedAddressesRLM?, _ error: NSError?) -> ()) {
        getRealm { (realmOpt, error) in
            if let realm = realmOpt {
                try! realm.write {
                    completion(realm.objects(SavedAddressesRLM.self).first, nil)
                }
            } else {
                let savedAddresses = SavedAddressesRLM()
                savedAddresses.addresses = [String: String]()
                completion(savedAddresses, error)
            }
        }
    }
}

extension RealmMigrationManager {
    func migrateFrom6To7(with migration: Migration) {
        migration.enumerateObjects(ofType: SpendableOutputRLM.className()) { (_, newSpendOut) in
            newSpendOut?["addressID"] = NSNumber(value: 0)
        }
    }
    
    func migrateFrom7To8(with migration: Migration) {
        migration.enumerateObjects(ofType: AccountRLM.className()) { (_, newAccount) in
            newAccount?["backupSeedPhrase"] = ""
        }
    }
    
    func migrateFrom8To9(with migration: Migration) {
        migration.enumerateObjects(ofType: AccountRLM.className()) { (_, newAccount) in
            newAccount?["topIndex"] = NSNumber(value: 0)
        }
    }
    
    func migrateFrom9To10(with migration: Migration) {
        migration.enumerateObjects(ofType: SpendableOutputRLM.className()) { (_, newSpendableOutput) in
            newSpendableOutput?["txStatus"] = ""
        }
    }
    
    func migrateFrom10To11(with migration: Migration) {
        migration.enumerateObjects(ofType: HistoryRLM.className()) { (oldHistoryRLM, newHistoryRLM) in
            newHistoryRLM?["walletIndex"] = NSNumber(value: oldHistoryRLM?["walletIndex"] as? Int ?? 0)
        }
        
        migration.enumerateObjects(ofType: SpendableOutputRLM.className()) { (oldOutput, newOutput) in
            newOutput?["transactionStatus"] = oldOutput?["txStatus"]
        }
    }
    
    func migrateFrom11To12(with migration: Migration) {
        migration.enumerateObjects(ofType: HistoryRLM.className()) { (oldHistoryRLM, newHistoryRLM) in
            if let intStatus = Int(oldHistoryRLM?["txStatus"] as! String) {
                newHistoryRLM?["txStatus"] = NSNumber(value: intStatus)
            } else {
                newHistoryRLM?["txStatus"] = NSNumber(value: 0)
            }
        }
    }
    
    func migrateFrom12To13(with migration: Migration) {
        migration.enumerateObjects(ofType: AddressRLM.className()) { (_, newAddress) in
            newAddress?["lastActionDate"] = Date()
        }
    }
    
    func migrateFrom13To14(with migration: Migration) {
        migration.enumerateObjects(ofType: UserWalletRLM.className()) { (_, newWallet) in
            newWallet?["chainType"] = NSNumber(value: 0)
        }
    }
    
    func migrateFrom14To15(with migration: Migration) {
        migration.enumerateObjects(ofType: UserWalletRLM.className()) { (_, newWallet) in
            newWallet?["isTherePendingTx"] = NSNumber(booleanLiteral: false)
        }
    }
    
    func migrateFrom15To16(with migration: Migration) {
//        migration.enumerateObjects(ofType: UserWalletRLM.className()) { (_, newWallet) in
//            newWallet?["networkID"] = NSNumber(value: 0)
//        }
    }
    
    func migrateFrom16To17(with migration: Migration) {
        migration.enumerateObjects(ofType: AddressRLM.className()) { (_, newAddress) in
            newAddress?["amountString"] = String()
        }
        migration.enumerateObjects(ofType: ETHWallet.className()) { (_, newETHWallet) in
            newETHWallet?["balance"] = String()
        }
        migration.enumerateObjects(ofType: HistoryRLM.className()) { (_, newHistoryRLM) in
            newHistoryRLM?["gasLimit"] = NSNumber(value: 0)
            newHistoryRLM?["gasPrice"] = NSNumber(value: 0)
            newHistoryRLM?["txOutAmountString"] = String()
        }
    }
    
    func migrateFrom17To18(with migration: Migration) {
        migration.enumerateObjects(ofType: StockExchangeRateRLM.className()) { (_, newRates) in
            newRates?["btc2usd"] = NSNumber(value: 0)
        }
    }
    
    func migrateFrom18To19(with migration: Migration) {
        migration.enumerateObjects(ofType: UserWalletRLM.className()) { (_, newWallet) in
            newWallet?["lastActivityTimestamp"] = NSNumber(value: 0)
        }
    }
    
    func migrateFrom19To20(with migration: Migration) {
        migration.enumerateObjects(ofType: RecentAddressesRLM.className()) { (_, newRecentAddress) in
            newRecentAddress?["lastActionDate"] = Date()
            newRecentAddress?["blockchain"] = NSNumber(value: 0)
            newRecentAddress?["blockchainNetType"] = NSNumber(value: 0)
        }
    }
    
    func migrateFrom20To21(with migration: Migration) {
        migration.enumerateObjects(ofType: AddressRLM.className()) { (_, newAddress) in
            newAddress?["networkID"] = NSNumber(value: 0)
        }
    }
    
    func migrateFrom21To22(with migration: Migration) {
        migration.enumerateObjects(ofType: UserWalletRLM.className()) { (_, newWallet) in
            newWallet?["isSyncing"] = NSNumber(booleanLiteral: false)
        }
    }
    
    func migrateFrom22To23(with migration: Migration) {
        migration.enumerateObjects(ofType: HistoryRLM.className()) { (_, newHistory) in
            newHistory?["isMultisigTx"] = NSNumber(booleanLiteral: false)
            newHistory?["isWaitingConfirmation"] = NSNumber(booleanLiteral: false)
        }
    }
    
    func migrateFrom23To24(with migration: Migration) {
        migration.enumerateObjects(ofType: UserWalletRLM.className()) { (_, newWallet) in
            newWallet?["multisigWallet"] = nil
        }
    }
    
    func migrateFrom24To25(with migration: Migration) {
        migration.enumerateObjects(ofType: HistoryRLM.className()) { (_, newHistory) in
            newHistory?["nonce"] = NSNumber(value: 0)
            newHistory?["input"] = String()
            newHistory?["contractAddress"] = String()
            newHistory?["methodInvoked"] = String()
            newHistory?["invocationStatus"] = NSNumber(booleanLiteral: false)
            newHistory?["owners"] = List<MultisigTransactionOwnerRLM>()
        }
    }
    
    func migrateFrom25To26(with migration: Migration) {
        migration.enumerateObjects(ofType: HistoryRLM.className()) { (_, newHistory) in
            newHistory?["isMultisigTx"] = NSNumber(booleanLiteral: false)
        }
    }
    
    func migrateFrom26To27(with migration: Migration) {
        migration.enumerateObjects(ofType: HistoryRLM.className()) { (_, newHistory) in
            newHistory?["multisig"] = nil
        }
    }
    
    func migrateFrom27To28(with migration: Migration) {
        migration.enumerateObjects(ofType: MultisigTransactionRLM.className()) { (_, newTx) in
            newTx?["index"] = NSNumber(value: 0)
        }
    }
    
    func migrateFrom28To29(with migration: Migration) {
        migration.enumerateObjects(ofType: UserWalletRLM.className()) { (_, wallet) in
            wallet?["importedPrivateKey"] = String()
            wallet?["importedPublicKey"] = String()
        }
    }
    
    func migrateFrom29To30(with migration: Migration) {
        migration.enumerateObjects(ofType: MultisigWallet.className()) { (_, msWallet) in
            msWallet?["isActivePaymentRequest"] = Bool()
        }
    }
    func migrateFrom30To31(with migration: Migration) {
        UserPreferences.shared.writeDBPrivateKeyFixValue(false)
    }
    func migrateFrom31To32(with migration: Migration) {
        migration.enumerateObjects(ofType: TokenRLM.className()) { (_, token) in
            token?["decimals"] = Int(-1)
            token?["currencyID"] = UInt32(0)
            token?["netType"] = Int(0)
        }
    }
}

extension LegacyCodeManager {
    //Greedy algorithm
    func spendableOutput(wallet: UserWalletRLM) -> [SpendableOutputRLM] {
        let ouputs = List<SpendableOutputRLM>()
        
        let addresses = wallet.addresses
        for address in addresses {
            //add checking output (in/out)
            
            for out in address.spendableOutput {
                ouputs.append(out)
            }
        }
        
        let results = ouputs.sorted(by: { (out1, out2) -> Bool in
            out1.transactionOutAmount.uint64Value > out2.transactionOutAmount.int64Value
        })
        
        return results
    }
    
    func greedySubSet(outputs: [SpendableOutputRLM], threshold: UInt64) -> [SpendableOutputRLM] {
        var sum = spendableOutputSum(outputs: outputs)
        var result = outputs
        
        if sum < threshold {
            return [SpendableOutputRLM]()
        }
        
        var index = 0
        while index < result.count {
            let output = result[index]
            if sum > threshold + output.transactionOutAmount.uint64Value {
                sum = sum - output.transactionOutAmount.uint64Value
                result.remove(at: index)
            } else {
                index += 1
            }
        }
        
        return result
    }
    
    func spendableOutputSum(outputs: [SpendableOutputRLM]) -> UInt64 {
        var sum = UInt64(0)
        
        for output in outputs {
            sum += output.transactionOutAmount.uint64Value
        }
        
        return sum
    }
}

extension TokensManager {
    func updateErc20Tokens(tokens: [TokenRLM]) {
        //tokens need to be updated iff token.decimals missing iff token.decimals = -1
        // after update this value will be non-negative
        getRealm { [unowned self] (realmOpt, error) in
            if let realm = realmOpt {
                var neededUpdateArray = [TokenRLM]()
                
                try! realm.write {
                    for token in tokens {
                        let object = realm.object(ofType: TokenRLM.self, forPrimaryKey: token.contractAddress)
                        
                        if let oldToken = object {
                            oldToken.name       = token.name
                            oldToken.ticker     = token.ticker
                            
                            //decimals
                            if oldToken.decimals == -1 {//case: there was no info
                                oldToken.decimals = token.decimals
                            } else if token.decimals != -1 {//case: there is correct value of decimals (that maybe changed)
                                oldToken.decimals   = token.decimals
                            }
                            
                            if oldToken.decimals == -1 {
                                neededUpdateArray.append(oldToken)
                            }
                            
                            realm.add(oldToken, update: true)
                        } else {
                            if token.decimals == -1 {
                                neededUpdateArray.append(token)
                            }
                            
                            realm.add(token, update: true)
                        }
                    }
                }
                
                let tokens = realm.objects(TokenRLM.self)
                self.erc20Tokens.removeAll()
                tokens.forEach{ self.erc20Tokens[$0.contractAddress] = $0 }
                
                if neededUpdateArray.isEmpty == false {
                    DataManager.shared.updateTokensInfo(neededUpdateArray)
                }
            }
        }
    }
    
    func getErc20TokenBy(address: String, completion: @escaping(_ token: TokenRLM) -> ()) {
        getRealm { (realmOpt, err) in
            if let realm = realmOpt {
                completion(realm.object(ofType: TokenRLM.self, forPrimaryKey: address)!)
            }
        }
    }
}
