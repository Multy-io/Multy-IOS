//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift
//import MultyCoreLibrary

private typealias WalletUpdateRLM = UserWalletRLM
private typealias ETHWalletRLM = UserWalletRLM

//enum ahould be without gaps
enum WalletBrokenState: Int, CaseIterable {
    case
    normal              = 0,
    fixedPrivateKey     = 1
    
    init!(_ value: Int) {
        if 0 <= value && value < WalletBrokenState.allCases.count {
            self.init(rawValue: value)!
        } else {
            self.init(rawValue: 0)
        }
    }
}

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
    
    @objc dynamic var importedPrivateKey = String()
    @objc dynamic var importedPublicKey = String()
    
    @objc dynamic var brokenState = NSNumber(value: 0)
    
    var changeAddressIndex: UInt32 {
        get {
            switch blockchainType.blockchain {
            case BLOCKCHAIN_BITCOIN:
                return UInt32(addresses.count)
            case BLOCKCHAIN_ETHEREUM:
                return 0
            case BLOCKCHAIN_ERC20:
                return 0
            default:
                return 0
            }
        }
    }
    
    var shouldFixPrivateKey: Bool {
        return WalletBrokenState(brokenState.intValue) == .fixedPrivateKey
    }
    
    var isWalletFixed: Bool {
        return WalletBrokenState(brokenState.intValue) == .fixedPrivateKey && !importedPrivateKey.isEmpty
    }
    
    var isEmpty: Bool {
        get {
            return sumInCryptoString == "0" || sumInCryptoString == "0,0"
        }
    }
    
    var isTokenExist: Bool {
        return (ethWallet?.erc20Tokens.count ?? 0) > 0 ? true : false
    }
    
    var sumInCryptoString: String {
        switch blockchain {
        case BLOCKCHAIN_BITCOIN:
            return sumInCrypto.fixedFraction(digits: 8)
        case BLOCKCHAIN_ETHEREUM:
            return allETHBalance.cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
        case BLOCKCHAIN_ERC20:
            return availableAmount.cryptoValueString(for: token)
        default:
            return ""
        }
    }
    
    var sumInFiatString: String {
        switch blockchain {
        case BLOCKCHAIN_BITCOIN:
            return sumInFiat.fixedFraction(digits: 2)
        case BLOCKCHAIN_ETHEREUM:
            return (allETHBalance * exchangeCourse).fiatValueString(for: BLOCKCHAIN_ETHEREUM)
        case BLOCKCHAIN_ERC20:
            return "0"
        default:
            return "0"
        }
    }
    
    var sumInFiat: Double {
        switch blockchain {
        case BLOCKCHAIN_BITCOIN:
            return sumInCrypto * exchangeCourse
        case BLOCKCHAIN_ETHEREUM:
            return Double((allETHBalance * exchangeCourse).fiatValueString(for: BLOCKCHAIN_ETHEREUM).replacingOccurrences(of: ",", with: "."))!
        case BLOCKCHAIN_ERC20:
            return 0
        default:
            return 0
        }
    }
    
    var isThereBlockedAmount: Bool {
        return isTherePendingTx.boolValue
    }
    
    //available part
    var availableAmount: BigInt {
        var result = BigInt.zero()
        
        switch blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            result = BigInt(sumInCryptoString.convertToSatoshiAmountString()) - blockedAmount
        case BLOCKCHAIN_ETHEREUM:
            result = availableBalance
        case BLOCKCHAIN_ERC20:
            result = BigInt(ethWallet!.balance)
        default:
            break
        }
        
        return result
    }
    
    var availableAmountString: String {
        if blockchain == BLOCKCHAIN_ERC20 {
            return availableAmount.cryptoValueString(for: token)
        } else {
            return availableAmount.cryptoValueString(for: blockchain)
        }
    }
    
    var availableAmountInFiat: BigInt {
        return availableAmount * exchangeCourse
    }
    
    var availableAmountInFiatString: String {
        return availableAmountInFiat.fiatValueString(for: blockchain)
    }
    
    //blocked part
    var blockedAmount: BigInt {
        switch blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            return BigInt("\(calculateBlockedAmount())")
        case BLOCKCHAIN_ETHEREUM:
            return ethWallet!.pendingBalance
        default:
            return BigInt("0")
        }
    }
    
    var blockedAmountString: String {
        return blockedAmount.cryptoValueString(for: blockchain)
    }
    
    var blolckedInFiat: BigInt {
        return blockedAmount * exchangeCourse
    }
    
    var blolckedInFiatString: String {
        return blolckedInFiat.fiatValueString(for: blockchain)
    }
    
    //////////////////////////////////////
    //not unified
    
    var blockchainType: BlockchainType {
        return BlockchainType.create(wallet: self)
    }

    var blockchain: Blockchain {
        return blockchainType.blockchain
    }
    
    var availableSumInCrypto: Double {
        if self.blockchainType.blockchain == BLOCKCHAIN_BITCOIN {
            return availableAmount.cryptoValueString(for: BLOCKCHAIN_BITCOIN).stringWithDot.doubleValue
        } else {
            return 0
        }
    }
    
    var shouldCreateNewAddressAfterTransaction: Bool {
        return blockchainType.blockchain == BLOCKCHAIN_BITCOIN
    }
    
    var isMultiSig: Bool {
        return multisigWallet != nil
    }
    
    var isImported: Bool {
        return walletID.int32Value < 0
    }
    
    var isImportedForPrimaryKey: Bool {
        return walletID.int32Value < 0 || isWalletFixed
    }
    
    var isImportedHasKey: Bool {
        if isImportedForPrimaryKey {
            return importedPrivateKey != ""
        } else {
            return true
        }
    }
    
    @objc dynamic var fiatName = String()
    @objc dynamic var fiatSymbol = String()
    
    @objc dynamic var address = String()
    
    @objc dynamic var historyAddress : AddressRLM?
    
    @objc dynamic var isTherePendingTx = NSNumber(value: 0)
    
    @objc dynamic var ethWallet: ETHWallet?
    @objc dynamic var btcWallet: BTCWallet?
    @objc dynamic var multisigWallet: MultisigWallet?
    
    weak var tokenHolderWallet: UserWalletRLM?
    
    var token: TokenRLM? {
        return DataManager.shared.realmManager.erc20Tokens[address.lowercased()]
    }
    
    var exchangeCourse: Double {
        return DataManager.shared.makeExchangeFor(blockchainType: blockchainType)
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
    
    var mainWalletWithTokenWallets: [UserWalletRLM] {
        return [self] + tokenWallets
    }
    
    var tokenWallets: [UserWalletRLM] {
        if ethWallet == nil {
            return [UserWalletRLM]()
        } else {
            weak var weakSelf = self
            
            return ethWallet!.erc20Tokens.map { weakSelf!.createTokenWallet(for: $0) }
        }
    }
    
    func createTokenWallet(for token: WalletTokenRLM) -> UserWalletRLM {
        let tokenWallet = UserWalletRLM()
        
        tokenWallet.address = token.address
        tokenWallet.name = token.name
        tokenWallet.chain = NSNumber(value: token.token?.blockchainType.blockchain.rawValue ?? 0)
        tokenWallet.chainType = chainType
        tokenWallet.cryptoName = token.ticker
        
        tokenWallet.ethWallet = ETHWallet()
        tokenWallet.ethWallet!.balance = token.balance
        
        tokenWallet.tokenHolderWallet = self
        
        return tokenWallet
    }
    
    func createTokenWallet(for token: TokenRLM) -> UserWalletRLM {
        let tokenWallet = UserWalletRLM()
        
        tokenWallet.address = token.contractAddress
        tokenWallet.name = token.name
        tokenWallet.chain = NSNumber(value: token.blockchainType.blockchain.rawValue)
        tokenWallet.chainType = chainType
        tokenWallet.cryptoName = token.ticker
        
        tokenWallet.ethWallet = ETHWallet()
        tokenWallet.ethWallet!.balance = "0"
        
        tokenWallet.tokenHolderWallet = self
        
        return tokenWallet
    }
    
    var isTokenWallet: Bool {
        return tokenHolderWallet != nil
    }
    
    func confirmationStatusForTransaction(transaction : HistoryRLM) -> ConfirmationStatus {
        var result = ConfirmationStatus.waiting
        if isMultiSig && transaction.multisig != nil {
            let currentOwner = multisigWallet?.owners.filter {$0.associated == true}.first
            guard currentOwner != nil else {
                return result
            }
            
            let transactionOwner = transaction.multisig!.owners.filter {$0.address == currentOwner!.address}.first
            if transactionOwner != nil {
                result = ConfirmationStatus(rawValue: transactionOwner!.confirmationStatus.intValue)!
            }
        }
        return result
    }
    
    func currentTransactionOwner(transaction : HistoryRLM) -> MultisigTransactionOwnerRLM? {
        var result : MultisigTransactionOwnerRLM?
        if isMultiSig && transaction.multisig != nil {
            let currentOwner = multisigWallet?.owners.filter {$0.associated == true}.first
            guard currentOwner != nil else {
                return nil
            }
            
            result = transaction.multisig!.owners.filter {$0.address == currentOwner!.address}.first
        }
        
        return result
    }
    
    func isRejected(tx: HistoryRLM) -> Bool {
        guard tx.multisig != nil else {
            return false
        }
        let declinedCount = tx.multisig!.owners.reduce(0) {
            $0 + ($1.confirmationStatus.intValue == MultisigOwnerTxStatus.msOwnerStatusDeclined.rawValue ? 1 : 0)
        }
//        let declinedCount = tx.multisig!.owners.filter { $0.confirmationStatus.intValue == MultisigOwnerTxStatus.msOwnerStatusDeclined.rawValue }.count
        
        return declinedCount + multisigWallet!.signaturesRequiredCount > multisigWallet!.ownersCount
    }
    
    class func checkMissingTokens(array: List<UserWalletRLM>) {
        var addressesSet = Set<TokenRLM>()
        array.forEach { wallet in
            if let tokenArray = wallet.ethWallet?.erc20Tokens {
                let blockchainType = BlockchainType(blockchain: BLOCKCHAIN_ERC20, net_type: wallet.blockchainType.net_type)
                tokenArray.forEach { if $0.token == nil { addressesSet.insert(TokenRLM.createWith($0.address, blockchainType: blockchainType)) } }
            }
        }
        
        DataManager.shared.updateTokensInfo(Array(addressesSet))
    }
    
    class func checkMissingTokens(array: [UserWalletRLM]) {
        var addressesSet = Set<TokenRLM>()
        array.forEach { wallet in
            if let tokenArray = wallet.ethWallet?.erc20Tokens {
                let blockchainType = BlockchainType(blockchain: BLOCKCHAIN_ERC20, net_type: wallet.blockchainType.net_type)
                tokenArray.forEach{ if $0.token == nil { addressesSet.insert(TokenRLM.createWith($0.address, blockchainType: blockchainType)) } }
            }
        }
        
        DataManager.shared.updateTokensInfo(Array(addressesSet))
    }
    
    public class func initWithArray(walletsInfo: NSArray) -> List<UserWalletRLM> {
        let wallets = List<UserWalletRLM>()
        
        for walletInfo in walletsInfo {
            let wallet = UserWalletRLM.initWithInfo(walletInfo: walletInfo as! NSDictionary)
            wallets.append(wallet)
        }
        
        checkMissingTokens(array: wallets)
        
        return wallets
    }
    
    public class func initArrayWithArray(walletsArray: NSArray) -> [UserWalletRLM] {
        var wallets = [UserWalletRLM]()
        
        for walletInfo in walletsArray {
            let wallet = UserWalletRLM.initWithInfo(walletInfo: walletInfo as! NSDictionary)
            wallets.append(wallet)
        }
        
        checkMissingTokens(array: wallets)
        
        return wallets
    }
    
    public class func initWithInfo(walletInfo: NSDictionary) -> UserWalletRLM {
        let wallet = UserWalletRLM()
        
        if let privateKey = walletInfo["importedPrivateKey"] {
            wallet.importedPrivateKey = privateKey as! String
        }
        
        if let publicKey = walletInfo["importedPublicKey"] {
            wallet.importedPublicKey = publicKey as! String
        }
        
        if let chain = walletInfo["currencyid"]  {
            wallet.chain = NSNumber(value: chain as! UInt32)
        }
        
        if let chainType = walletInfo["networkid"]  {
            wallet.chainType = NSNumber(value: chainType as! UInt32)
        }
        
        //MARK: to be deleted
        if let walletID = walletInfo["WalletIndex"]  {
            wallet.walletID = NSNumber(value: walletID as! Int32)
        }
        
        if let walletID = walletInfo["walletindex"]  {
            wallet.walletID = NSNumber(value: walletID as! Int32)
        }
        
        if let walletName = walletInfo["walletname"] {
            wallet.name = walletName as! String
        }
        
        if let brokenState = walletInfo["brokenStatus"] as? NSNumber {
            wallet.brokenState = brokenState
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
        if walletInfo["walletindex"] != nil || walletInfo["WalletIndex"] != nil {
            if !wallet.isMultiSig && !wallet.isImported {
                wallet.id = DataManager.shared.generateWalletPrimaryKey(currencyID: wallet.chain.uint32Value, networkID: wallet.chainType.uint32Value, walletID: wallet.walletID.int32Value)
            } else if wallet.isMultiSig {
                // Multisig wallet
                wallet.id = DataManager.shared.generateMultisigWalletPrimaryKey(currencyID: wallet.chain.uint32Value, networkID: wallet.chainType.uint32Value, inviteCode: wallet.multisigWallet!.inviteCode)
                let owner = wallet.multisigWallet!.owners.filter { $0.associated == true }.first
                if owner != nil {
                    let isLinkedWalletImported = owner!.walletIndex == -1
                    
                    if isLinkedWalletImported {
                        wallet.multisigWallet!.linkedWalletID = DataManager.shared.generateImportedWalletPrimaryKey(currencyID: wallet.chain.uint32Value, networkID: wallet.chainType.uint32Value, address: owner!.address) //DataManager.shared.generateWalletPrimaryKey(currencyID: wallet.chain.uint32Value, networkID: wallet.chainType.uint32Value, walletID: owner!.address.int32Value, inviteCode:nil)
                    } else {
                        wallet.multisigWallet?.linkedWalletID = DataManager.shared.generateWalletPrimaryKey(currencyID: wallet.chain.uint32Value, networkID: wallet.chainType.uint32Value, walletID: owner!.walletIndex.int32Value)
                    }
                }
            } else {
                // Imported wallet
                wallet.id = DataManager.shared.generateImportedWalletPrimaryKey(currencyID: wallet.chain.uint32Value, networkID: wallet.chainType.uint32Value, address: wallet.address)
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
            return amount.convertCryptoAmountStringToMinimalUnits(for: BLOCKCHAIN_BITCOIN) < Constants.BigIntSwift.oneBTCInSatoshiKey * sumInCrypto
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
        return ["availableSumInCrypto", "availableSumInFiat", "tokenHolderWaller"]
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
    
    func isAddressBelongsToWallet(_ address: String) -> Bool {
        var result = false
        switch blockchain {
        case BLOCKCHAIN_BITCOIN:
            let matchingAddresses = addresses.filter {$0.address == address}
            if matchingAddresses.count > 0 {
                result = true
            }
            break
            
        case BLOCKCHAIN_ETHEREUM:
            result = self.address == address
            break
            
        default:
            break
        }
        
        return result
    }
    
    func txAmount(_ tx: HistoryRLM) -> BigInt {
        var result = BigInt.zero()
        switch blockchain {
        case BLOCKCHAIN_BITCOIN:
            result = BigInt("\(outgoingAmount(for: tx))") - tx.fee(for: blockchain)
            
        //  return txOutAmount.doubleValue.fixedFraction(digits: 8)
        case BLOCKCHAIN_ETHEREUM:
            result = BigInt(tx.txOutAmountString)
            
            if tx.isOutcoming() && tx.multisig == nil {
                result = result + tx.fee(for: blockchain)
            }
        //   return txOutAmountString.appendDelimeter(at: 18)
        default:
            break
            //return ""
        }
        
        return result
    }
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
        
        if let addressesArr = infoDict["addresses"] as? NSArray,
            let addressObj = addressesArr.firstObject as? NSDictionary,
            let tokensArr = addressObj["erc20balances"] as? NSArray {
            
            ethWallet?.erc20Tokens = WalletTokenRLM.initERC20With(infoArray: tokensArr)
        }
        
    }
    
    func updateMultiSigWallet(from infoDict: NSDictionary) {
        if let multisig = infoDict["multisig"] as? NSDictionary {
            multisigWallet = MultisigWallet()
            
            if chainType.intValue == ETHEREUM_CHAIN_ID_MAINNET.rawValue {
                multisigWallet!.chainType = NSNumber(value: ETHEREUM_CHAIN_ID_MULTISIG_MAINNET.rawValue)
            } else {
                multisigWallet!.chainType = NSNumber(value: ETHEREUM_CHAIN_ID_MULTISIG_TESTNET.rawValue)
            }
            
            if let ownersCount = multisig["ownersCount"] as? Int {
                multisigWallet!.ownersCount = ownersCount
            }
            
            if let signaturesRequired = multisig["confirmations"] as? Int {
                multisigWallet!.signaturesRequiredCount = signaturesRequired
            }
            
            if let inviteCode = multisig["inviteCode"] as? String {
                multisigWallet!.inviteCode = inviteCode
            }
            
            if let isHavePaymentRequest = multisig["havePaymentReqests"] as? Bool {
                multisigWallet!.isActivePaymentRequest = isHavePaymentRequest
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
                    
                    if owner.creator as! Bool && owner.associated as! Bool {
                        multisigWallet!.amICreator = true
                    }
                    
                    if owner.associated as! Bool {
                        multisigWallet!.linkedWalletAddress = owner.address
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
