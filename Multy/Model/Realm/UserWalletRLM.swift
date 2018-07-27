//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

private typealias WalletUpdateRLM = UserWalletRLM
private typealias ETHWalletRLM = UserWalletRLM

class UserWalletRLM: Object {
    @objc dynamic var id = String()    //
    @objc dynamic var chain = NSNumber(value: 0)    //UInt32
    @objc dynamic var chainType = NSNumber(value: 1)    //UInt32//BlockchainNetType
    @objc dynamic var walletID = NSNumber(value: 0) //UInt32
    @objc dynamic var addressID = NSNumber(value: 0) //UInt32
    
    @objc dynamic var privateKey = String()
    @objc dynamic var publicKey = String()
    
    @objc dynamic var name = String()
    @objc dynamic var cryptoName = String()  //like BTC
    @objc dynamic var sumInCrypto: Double = 0.0
    @objc dynamic var lastActivityTimestamp = NSNumber(value: 0)
    @objc dynamic var isSyncing = NSNumber(booleanLiteral: false)
    
    var changeAddressIndex: UInt32 {
        get {
            switch blockchainType.blockchain {
            case BLOCKCHAIN_BITCOIN:
                return UInt32(addresses.count)
            case BLOCKCHAIN_ETHEREUM:
                return 0
            default:
                return 0
            }
        }
    }
    
    var isEmpty: Bool {
        get {
            return sumInCryptoString == "0" || sumInCryptoString == "0,0"
        }
    }
    
    var sumInCryptoString: String {
        get {
            switch blockchainType.blockchain {
            case BLOCKCHAIN_BITCOIN:
                return sumInCrypto.fixedFraction(digits: 8)
            case BLOCKCHAIN_ETHEREUM:
                return allETHBalance.cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
            default:
                return ""
            }
        }
    }
    
    var sumInFiatString: String {
        get {
            if self.blockchainType.blockchain == BLOCKCHAIN_BITCOIN {
                return sumInFiat.fixedFraction(digits: 2)
            } else {
                return (allETHBalance * exchangeCourse).fiatValueString(for: BLOCKCHAIN_ETHEREUM)
            }
        }
    }
    
    var sumInFiat: Double {
        get {
            if self.blockchainType.blockchain == BLOCKCHAIN_BITCOIN {
                return sumInCrypto * exchangeCourse
            } else {
                return Double((allETHBalance * exchangeCourse).fiatValueString(for: BLOCKCHAIN_ETHEREUM).replacingOccurrences(of: ",", with: "."))!
            }
        }
    }
    
    var isThereBlockedAmount: Bool {
        get {
            return isTherePendingTx.boolValue
        }
    }
    
    //available part
    var availableAmount: BigInt {
        get {
            switch blockchainType.blockchain {
            case BLOCKCHAIN_BITCOIN:
                return BigInt(sumInCryptoString.convertToSatoshiAmountString()) - blockedAmount
            case BLOCKCHAIN_ETHEREUM:
                return availableBalance
            default:
                return BigInt("0")
            }
        }
    }
    
    var availableAmountString: String {
        get {
            return availableAmount.cryptoValueString(for: blockchain)
        }
    }
    
    var availableAmountInFiat: BigInt {
        get {
            return availableAmount * exchangeCourse
        }
    }
    
    var availableAmountInFiatString: String {
        get {
            return availableAmountInFiat.fiatValueString(for: blockchain)
        }
    }
    
    //blocked part
    var blockedAmount: BigInt {
        get {
            switch blockchainType.blockchain {
            case BLOCKCHAIN_BITCOIN:
                return BigInt("\(calculateBlockedAmount())")
            case BLOCKCHAIN_ETHEREUM:
                return ethWallet!.pendingBalance
            default:
                return BigInt("0")
            }
        }
    }
    
    var blockedAmountString: String {
        get {
            return blockedAmount.cryptoValueString(for: blockchain)
        }
    }
    
    var blolckedInFiat: BigInt {
        get {
            return blockedAmount * exchangeCourse
        }
    }
    
    var blolckedInFiatString: String {
        get {
            return blolckedInFiat.fiatValueString(for: blockchain)
        }
    }
    
    //////////////////////////////////////
    //not unified
    
    var blockchainType: BlockchainType {
        get {
            return BlockchainType.create(wallet: self)
        }
    }

    var blockchain: Blockchain {
        get {
            return blockchainType.blockchain
        }
    }
    
    var availableSumInCrypto: Double {
        get {
            if self.blockchainType.blockchain == BLOCKCHAIN_BITCOIN {
                return availableAmount.cryptoValueString(for: BLOCKCHAIN_BITCOIN).stringWithDot.doubleValue
            } else {
                return 0
            }
        }
    }
    
    var shouldCreateNewAddressAfterTransaction: Bool {
        return blockchainType.blockchain  == BLOCKCHAIN_BITCOIN
    }
    
    var isMultiSig: Bool {
        return multisigWallet != nil
    }
    
    @objc dynamic var fiatName = String()
    @objc dynamic var fiatSymbol = String()
    
    @objc dynamic var address = String()
    
    @objc dynamic var historyAddress : AddressRLM?
    
    @objc dynamic var isTherePendingTx = NSNumber(value: 0)
    
    @objc dynamic var ethWallet: ETHWallet?
    @objc dynamic var btcWallet: BTCWallet?
    @objc dynamic var multisigWallet: MultisigWallet?

    var exchangeCourse: Double {
        get {
            return DataManager.shared.makeExchangeFor(blockchainType: blockchainType)
        }
    }
    
    var addresses = List<AddressRLM>() {
        didSet {
            var sum : UInt64 = 0
            
            for address in addresses {
                for out in address.spendableOutput {
                    sum += out.transactionOutAmount.uint64Value
                }
            }
            
            sumInCrypto = sum.btcValue
            
            address = addresses.last?.address ?? ""
        }
    }
    
    public class func initWithArray(walletsInfo: NSArray) -> List<UserWalletRLM> {
        let wallets = List<UserWalletRLM>()
        
        for walletInfo in walletsInfo {
            let wallet = UserWalletRLM.initWithInfo(walletInfo: walletInfo as! NSDictionary)
            wallets.append(wallet)
        }
        
        return wallets
    }
    
    public class func initArrayWithArray(walletsArray: NSArray) -> [UserWalletRLM] {
        var wallets = [UserWalletRLM]()
        
        for walletInfo in walletsArray {
            let wallet = UserWalletRLM.initWithInfo(walletInfo: walletInfo as! NSDictionary)
            wallets.append(wallet)
        }
        
        return wallets
    }
    
    public class func initWithInfo(walletInfo: NSDictionary) -> UserWalletRLM {
        let wallet = UserWalletRLM()
        wallet.ethWallet = ETHWallet()
        wallet.btcWallet = BTCWallet()
        
        if let chain = walletInfo["currencyid"]  {
            wallet.chain = NSNumber(value: chain as! UInt32)
        }
        
        if let chainType = walletInfo["networkid"]  {
            wallet.chainType = NSNumber(value: chainType as! UInt32)
        }
        
        //MARK: to be deleted
        if let walletID = walletInfo["WalletIndex"]  {
            wallet.walletID = NSNumber(value: walletID as! UInt32)
        }
        
        if let walletID = walletInfo["walletindex"]  {
            wallet.walletID = NSNumber(value: walletID as! UInt32)
        }
        
        if let walletName = walletInfo["walletname"] {
            wallet.name = walletName as! String
        }
        
        if let isTherePendingTx = walletInfo["pending"] as? Bool {
            wallet.isTherePendingTx = NSNumber(booleanLiteral: isTherePendingTx)
        }
        
        if let lastActivityTimestamp = walletInfo["lastactiontime"] as? Int {
            wallet.lastActivityTimestamp = NSNumber(value: lastActivityTimestamp)
        }
        
        if let isSyncing = walletInfo["issyncing"] as? Bool {
            wallet.isSyncing = NSNumber(booleanLiteral: isSyncing)
        }
        
        //parse addition info for each chain
        wallet.updateSpecificInfo(from: walletInfo)
        
        wallet.updateWalletWithInfo(walletInfo: walletInfo)
        
        //MARK: temporary only 0-currency
        //MARK: server BUG: WalletIndex and walletindex
        //No data from server
        let inviteCode = wallet.multisigWallet?.inviteCode
        if walletInfo["walletindex"] != nil || walletInfo["WalletIndex"] != nil {
            wallet.id = DataManager.shared.generateWalletPrimaryKey(currencyID: wallet.chain.uint32Value, networkID: wallet.chainType.uint32Value, walletID: wallet.walletID.uint32Value, inviteCode:inviteCode)
            
            if inviteCode != nil {
                let owner = wallet.multisigWallet?.owners.filter { $0.associated == true }.first
                
                guard owner != nil else {
                    return wallet
                }
                wallet.multisigWallet?.linkedWalletID = DataManager.shared.generateWalletPrimaryKey(currencyID: wallet.chain.uint32Value, networkID: wallet.chainType.uint32Value, walletID: wallet.walletID.uint32Value, inviteCode:nil)
            }
        }
        
        return wallet
    }
    
    public func updateWalletWithInfo(walletInfo: NSDictionary) {
        //MARK: to be deleted
        if let addresses = walletInfo["Adresses"] {
            self.addresses = AddressRLM.initWithArray(addressesInfo: addresses as! NSArray)
        }
        
        if let address = walletInfo["address"] as? NSDictionary {
            self.historyAddress = AddressRLM.initWithInfo(addressInfo: address)
        }
        
        if let addresses = walletInfo["addresses"] {
            if !(addresses is NSNull) {
                self.addresses = AddressRLM.initWithArray(addressesInfo: addresses as! NSArray)
            }
        }
        
        if let name = walletInfo["WalletName"] {
            self.name = name as! String
        }
        
        let blockchainType = BlockchainType.create(wallet: self)
        
        self.cryptoName = blockchainType.shortName
        self.fiatName = "USD"
        self.fiatSymbol = "$"
    }
    
    public func fetchAddresses() -> [String] {
        var addresses = [String]()
        self.addresses.forEach({ addresses.append($0.address) })
        
        return addresses
    }
    
    func calculateBlockedAmount() -> UInt64 {
        var sum = UInt64(0)
        
        for address in self.addresses {
            for out in address.spendableOutput {
                if out.transactionStatus.intValue == TxStatus.MempoolIncoming.rawValue {
                    sum += out.transactionOutAmount.uint64Value
                }
            }
        }
        
        return sum
    }
    
    func isThereAvailableAmount() -> Bool {
        switch blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            return availableAmount > Int64(0)
        case BLOCKCHAIN_ETHEREUM:
            return isThereAvailableBalance
        default:
            return true
        }
    }
    
    func isThereEnoughAmount(_ amount: String) -> Bool {
        switch blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            return amount.convertCryptoAmountStringToMinimalUnits(in: BLOCKCHAIN_BITCOIN) < Constants.BigIntSwift.oneBTCInSatoshiKey * sumInCrypto
        case BLOCKCHAIN_ETHEREUM:
            return availableBalance > (Constants.BigIntSwift.oneETHInWeiKey * amount.stringWithDot.doubleValue)
        default:
            return true
        }
    }
    
//    func availableAmount() -> UInt64 {
//        var sum = UInt64(0)
//        switch self.blockchain.blockchain {
//        case BLOCKCHAIN_BITCOIN:
//            for address in self.addresses {
//                for out in address.spendableOutput {
//                    if out.transactionStatus.intValue == TxStatus.BlockIncoming.rawValue {
//                        sum += out.transactionOutAmount.uint64Value
//                    }/* else if out.transactionStatus.intValue == TxStatus.MempoolOutcoming.rawValue {
//                     let addresses = self.fetchAddresses()
//                     
//                     if addresses.contains(address.address) {
//                     sum += out.transactionOutAmount.uint64Value
//                     }
//                     }*/
//                }
//            }
//        case BLOCKCHAIN_ETHEREUM:
//            let sumString = BigInt(self.ethWallet!.balance).stringValue
//            sum = UInt64(sumString)!
//        default: break
//        }
//    
//        return sum
//    }
    
    func blockedAmount(for transaction: HistoryRLM) -> UInt64 {
        var sum = UInt64(0)
        
        if transaction.txStatus.intValue == TxStatus.MempoolIncoming.rawValue {
            sum += transaction.txOutAmount.uint64Value
        } else if transaction.txStatus.intValue == TxStatus.MempoolOutcoming.rawValue {
            let addresses = self.fetchAddresses()
            
            for tx in transaction.txOutputs {
                if addresses.contains(tx.address) {
                    sum += tx.amount.uint64Value
                }
            }
        }
        
        return sum
    }
    
    func outgoingAmount(for transaction: HistoryRLM) -> UInt64 {
        var allSum = UInt64(0)
        var ourSum = UInt64(0)
        
        for tx in transaction.txInputs {
            allSum += tx.amount.uint64Value
        }
        
        let addresses = self.fetchAddresses()
        
        for tx in transaction.txOutputs {
            if addresses.contains(tx.address) {
                ourSum += tx.amount.uint64Value
            }
        }
        
        return allSum - ourSum
    }
    
    func isTransactionPending(for transaction: HistoryRLM) -> Bool {
        if transaction.txStatus.intValue == TxStatus.MempoolIncoming.rawValue {
            return true
        } else if transaction.txStatus.intValue == TxStatus.MempoolOutcoming.rawValue {
            return true
        }
        
        return false
    }
    
    func isTherePendingAmount() -> Bool {
        for address in self.addresses {
            for out in address.spendableOutput {
                if out.transactionStatus.intValue == TxStatus.MempoolIncoming.rawValue && out.transactionOutAmount.uint64Value > 0 {
                    return true
                }
            }
        }
        
        return false
    }
    
    func outcomingTxAddress(for transaction: HistoryRLM) -> String {
        let arrOfOutputsAddresses = transaction.txOutputs.map{ $0.address }//.joined(separator: "\n")
        let donationAddress = arrOfOutputsAddresses.joined(separator: "\n").getDonationAddress(blockchainType: BlockchainType.create(wallet: self)) ?? ""
        let walletAddresses = self.fetchAddresses()
        
        for address in arrOfOutputsAddresses {
            if address != donationAddress && !walletAddresses.contains(address) {
                return address
            }
        }
        
        if donationAddress.isEmpty == false {
            return donationAddress
        }
        
        return arrOfOutputsAddresses[0]
    }
    
    func incomingTxAddress(for transaction: HistoryRLM) -> String {
        let arrOfOutputsAddresses = transaction.txInputs.map{ $0.address }//.joined(separator: "\n")
        let donationAddress = arrOfOutputsAddresses.joined(separator: "\n").getDonationAddress(blockchainType: BlockchainType.create(wallet: self)) ?? ""
        let walletAddresses = self.fetchAddresses()
        
        for address in arrOfOutputsAddresses {
            if address != donationAddress && !walletAddresses.contains(address) {
                return address
            }
        }
        
        return arrOfOutputsAddresses[0]
    }
    
    func stringAddressesWithSpendableOutputs() -> String {
        switch blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            return addressesWithSpendableOutputs().joined(separator: "\n")
        case BLOCKCHAIN_ETHEREUM:
            return address
        default:
            return ""
        }
    }
    
    func addressesWithSpendableOutputs() -> [String] {
        return addresses.filter{ addressRLM in addressRLM.spendableOutput.count != 0 }.map{ $0.address }
    }
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["availableSumInCrypto", "availableSumInFiat"]
    }
    
//    public func updateWallet(walletInfo: NSDictionary) {
//        
//        if let addresses = walletInfo["Adresses"] {
//            self.addresses = AddressRLM.initWithArray(addressesInfo: addresses as! NSArray)
//        }
//        
//        if let addresses = walletInfo["addresses"] {
//            if !(addresses is NSNull) {
//                for address in addresses {
//                    let address = address as! NSDictionary
//                    let addressID = address["addressIndex"] != nil ? address["addressindex"] : address["walletindex"]
//                    
//                    let modifiedWallet = accountWallets.filter("walletID = \(walletID)").first
//                }
//                
//                self.addresses = AddressRLM.initWithArray(addressesInfo: addresses as! NSArray)
//            }
//        }
//        
//        if let name = walletInfo["WalletName"] {
//            self.name = name as! String
//        }
//        
//        self.cryptoName = "BTC"
//        self.fiatName = "USD"
//        self.fiatSymbol = "$"
//    }
}

extension ETHWalletRLM {
    var isThereAvailableBalance: Bool {
        get {
            if ethWallet == nil {
                return false
            }
            
            return availableBalance > Int64(0)
        }
    }
    
    var allETHBalance: BigInt {
        get {
            if ethWallet == nil {
                return BigInt.zero()
            }
            
            return isTherePendingTx.boolValue ? ethWallet!.pendingBalance : ethWallet!.ethBalance
        }
    }
    
    var availableBalance: BigInt {
        get {
            if ethWallet == nil {
                return BigInt.zero()
            }
            
            return isTherePendingTx.boolValue ? (ethWallet!.ethBalance < ethWallet!.pendingBalance ? ethWallet!.ethBalance : BigInt.zero()) : ethWallet!.ethBalance
        }
    }
}

extension WalletUpdateRLM {
    func updateSpecificInfo(from infoDict: NSDictionary) {
        switch self.chain.uint32Value {
        case BLOCKCHAIN_BITCOIN.rawValue:
            break
        case BLOCKCHAIN_ETHEREUM.rawValue:
            updateETHWallet(from: infoDict)
            updateMultiSigWallet(from: infoDict)
        default:
            break
        }
    }
    
    
    func updateBTCWallet(from infoDict: NSDictionary) {
        
    }
    
    func updateETHWallet(from infoDict: NSDictionary) {
        if let balance = infoDict["balance"] as? String {
            ethWallet = ETHWallet()
            ethWallet!.balance = balance.isEmpty ? "0" : balance
        }
        
        if let nonce = infoDict["nonce"] as? NSNumber {
            ethWallet?.nonce = nonce
        }
        
        if let pendingBalance = infoDict["pendingbalance"] as? String {
            ethWallet!.pendingWeiAmountString = pendingBalance.isEmpty ? "0" : pendingBalance
            
            if ethWallet!.pendingWeiAmountString != "0" {
                isTherePendingTx = NSNumber(booleanLiteral: true)
            }
        }
    }
    
    func updateMultiSigWallet(from infoDict: NSDictionary) {
        if let multisig = infoDict["multisig"] as? NSDictionary {
            multisigWallet = MultisigWallet()
            
            if let ownersCount = multisig["ownersCount"] as? Int {
                multisigWallet!.ownersCount = ownersCount
            }
            
            if let signaturesRequired = multisig["confirmations"] as? Int {
                multisigWallet!.signaturesRequiredCount = signaturesRequired
            }
            
            if let inviteCode = multisig["inviteCode"] as? String {
                multisigWallet!.inviteCode = inviteCode
            }
            
            if let ownersStruct = multisig["owners"] as? [NSDictionary] {
                let owners = List<MultisigOwnerRLM>()
                for ownerStruct in ownersStruct {
                    let owner = MultisigOwnerRLM()
                    
                    if let userID = ownerStruct["userID"] as? String {
                        owner.userID = userID
                    }
                    
                    if let address = ownerStruct["address"] as? String {
                        owner.address = address
                    }
                    
                    if let associated = ownerStruct["associated"] as? Bool {
                        owner.associated = NSNumber(booleanLiteral: associated)
                    }
                    
                    if let walletIndex = ownerStruct["walletIndex"] as? Int {
                        owner.walletIndex = NSNumber(value: walletIndex)
                    }
                    
                    if let addressIndex = ownerStruct["addressIndex"] as? Int {
                        owner.addressIndex = NSNumber(value: addressIndex)
                    }
                    
                    if let creator = ownerStruct["creator"] as? Bool {
                        owner.creator = NSNumber(booleanLiteral: creator)
                    }
                    
                    owners.append(owner)
                }
                
                multisigWallet!.owners = owners
            }
            
            if let deployStatus = multisig["deployStatus"] as? Int {
                multisigWallet!.deployStatus = NSNumber(integerLiteral: deployStatus)
            }
            
            if let isDeleted = multisig["status"] as? Bool {
                multisigWallet!.isDeleted = NSNumber(booleanLiteral: isDeleted)
            }
            
            if let TxOfCreation = multisig["txOfCreation"] as? String {
                multisigWallet!.txOfCreation = TxOfCreation
            }
            
            if let factoryAddress = multisig["factoryAddress"] as? String {
                multisigWallet!.factoryAddress = factoryAddress
            }
        }
    }
}
