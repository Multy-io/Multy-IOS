//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift
import Alamofire

private typealias MultisigManager = DataManager
private typealias CoreLibPrivateKeyFixManager = DataManager
private typealias CoreLibInfoManager = DataManager
private typealias CoreLibETHManager = DataManager

extension DataManager {
//    func isDeviceJailbroken() -> Bool {
//        return coreLibManager.isDeviceJailbroken()
//    }
    
    func getMnenonicAllWords() -> Array<String> {
        return coreLibManager.mnemonicAllWords()
    }
    
    func getMnenonicArray() -> Array<String> {
        return coreLibManager.createMnemonicPhraseArray()
    }
    
    func startCoreTest() {
        coreLibManager.startTests()
    }
    
    func getRootString(from seedPhase: String) -> (String?, String?)  {
        var binaryData = coreLibManager.createSeedBinaryData(from: seedPhase)
        if binaryData != nil {
            return (coreLibManager.createExtendedKey(from: &binaryData!), nil)
        } else {
//            return (nil, "Seed phrase is too short")
            return(nil, "WRONG SEED")
        }
        
    }
    
    func localBlockchainType(blockchainType: BlockchainType) -> BlockchainType {
        if accountType != .metamask {
            return blockchainType
        }
        
        if blockchainType.blockchain == BLOCKCHAIN_ETHEREUM {
            if blockchainType.net_type == Int(ETHEREUM_CHAIN_ID_RINKEBY.rawValue) {
                var localBlockchainType = blockchainType
                localBlockchainType.net_type = 1
                
                return localBlockchainType
            } else {
                return blockchainType
            }
        } else {
            return blockchainType
        }
    }
    
    func localWalletID(blockchainType: BlockchainType, walletID: UInt32) -> UInt32 {
        if accountType != .metamask {
            return walletID
        }
        
        if blockchainType.blockchain == BLOCKCHAIN_ETHEREUM {
            return 0
        } else {
            return walletID
        }
    }
    
    func localAddressID(blockchainType: BlockchainType, walletID: UInt32, addressID: UInt32) -> UInt32 {
        if accountType != .metamask {
            return addressID
        }
        
        if blockchainType.blockchain == BLOCKCHAIN_ETHEREUM {
            return walletID
        } else {
            return addressID
        }
    }
    
//    func createWallet(from seedPhrase: String, currencyID : UInt32, walletID : UInt32, addressID: UInt32) -> Dictionary<String, Any>? {
//        var binaryData = coreLibManager.createSeedBinaryData(from: seedPhrase)
//        
//        
//    }
    
    func createPublicInfo(blockchainType: BlockchainType, privateKey: String) -> Result<Dictionary<String, Any>, String> {
        let localBlockchainType = self.localBlockchainType(blockchainType: blockchainType)
        
        return coreLibManager.createPublicInfo(blockchainType: localBlockchainType, privateKey: privateKey)
    }
    
    func createAddress(blockchainType: BlockchainType, walletID: UInt32, addressID: UInt32, binaryData: inout BinaryData) -> Dictionary<String, Any>? {
        let localBlockchainType = self.localBlockchainType(blockchainType: blockchainType)
        let localWalletID = self.localWalletID(blockchainType: blockchainType, walletID: walletID)
        let localAddressID = self.localAddressID(blockchainType: blockchainType, walletID: walletID, addressID: addressID)
        
        return coreLibManager.createAddress(blockchainType: localBlockchainType, walletID: localWalletID, addressID: localAddressID, binaryData: &binaryData)
    }
    
    func createNewWallet(for binaryData: inout BinaryData, blockchain: BlockchainType, walletID: UInt32) -> Dictionary<String, Any>? {
        let localBlockchainType = self.localBlockchainType(blockchainType: blockchain)
        let localWalletID = self.localWalletID(blockchainType: blockchain, walletID: walletID)
        let localAddressID = self.localAddressID(blockchainType: blockchain, walletID: walletID, addressID: 0)
        
        return coreLibManager.createWallet(from: &binaryData,blockchain: localBlockchainType, walletID: localWalletID, addressID: localAddressID)
    }
    
    func createPrivateKey(blockchain: BlockchainType, walletID: UInt32, addressID: UInt32, binaryData: inout BinaryData) -> UnsafeMutablePointer<OpaquePointer?>? {
        let localBlockchainType = self.localBlockchainType(blockchainType: blockchain)
        let localWalletID = self.localWalletID(blockchainType: blockchain, walletID: walletID)
        let localAddressID = self.localAddressID(blockchainType: blockchain, walletID: walletID, addressID: 0)
        
        return coreLibManager.createPrivateKey(blockchain: localBlockchainType, walletID: localWalletID, addressID: localAddressID, binaryData: &binaryData)
    }
    
    func createTransaction(addressPointer: UnsafeMutablePointer<OpaquePointer?>,
                           sendAddress: String,
                           sendAmountString: String,
                           feePerByteAmount: String,
                           isDonationExists: Bool,
                           donationAmount: String,
                           isPayCommission: Bool,
                           wallet: UserWalletRLM,
                           binaryData: inout BinaryData,
                           inputs: List<AddressRLM>) -> (String, Double, String) {
        
        return coreLibManager.createTransaction(addressPointer: addressPointer,
                                                sendAddress: sendAddress,
                                                sendAmountString: sendAmountString,
                                                feePerByteAmount: feePerByteAmount,
                                                isDonationExists: isDonationExists,
                                                donationAmount: donationAmount,
                                                isPayCommission: isPayCommission,
                                                wallet: wallet,
                                                binaryData: &binaryData,
                                                inputs: inputs)
    }
    
    func importWalletBy(privateKey: String, blockchain: BlockchainType, walletID: Int32) -> Dictionary<String, Any>? {
        return coreLibManager.importWallet(blockchain: blockchain, walletID: walletID, privateKey: privateKey)
    }
    
    func isAddressValid(address: String, for wallet: UserWalletRLM) -> (isValid: Bool, message: String?) {
        return coreLibManager.isAddressValid(address: address, for: wallet)
    }
    
    func isAddressValid(_ address: String, for blockchainType: BlockchainType) -> (isValid: Bool, message: String?) {
        return coreLibManager.isAddressValid(address, for: blockchainType)
    }
    
    func createAndSendDonationTransaction(transactionDTO: TransactionDTO, completion: @escaping(_ answer: String?,_ error: Error?) -> ()) {
        let core = DataManager.shared.coreLibManager
        let wallet = transactionDTO.choosenWallet!
        var binaryData = DataManager.shared.realmManager.account!.binaryDataString.createBinaryData()!
        
        let blockchainType = BlockchainType.create(wallet: transactionDTO.choosenWallet!)
        let addressData = core.createAddress(blockchainType: blockchainType,
                                             walletID: transactionDTO.choosenWallet!.walletID.uint32Value,
                                             addressID: UInt32(transactionDTO.choosenWallet!.addresses.count),
                                             binaryData: &binaryData)
        
        let trData = DataManager.shared.createTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                          sendAddress: transactionDTO.sendAddress!,
                                                          sendAmountString: transactionDTO.sendAmountString!,
                                                          feePerByteAmount: transactionDTO.BTCDTO!.feePerByte!.stringValue,
                                                          isDonationExists: false,
                                                          donationAmount: "0",
                                                          isPayCommission: false,
                                                          wallet: transactionDTO.choosenWallet!,
                                                          binaryData: &binaryData,
                                                          inputs: transactionDTO.choosenWallet!.addresses)
        
        if trData.1 < 0 {
            completion(trData.0, NSError(domain: "", code: 400, userInfo: nil))
            
            return
        }

        let newAddressParams = [
            "walletindex"   : wallet.walletID.intValue,
            "address"       : addressData!["address"] as! String,
            "addressindex"  : wallet.addresses.count,
            "transaction"   : trData.0,
            "ishd"          : NSNumber(booleanLiteral: true)
            ] as [String : Any]
        
        let params = [
            "currencyid": wallet.chain,
            "payload"   : newAddressParams
            ] as [String : Any]
        
        DataManager.shared.sendHDTransaction(transactionParameters: params) { (dict, error) in
            print("---------\(dict)")
            
            //FIXME: create messages in bad cases
            if error != nil {
                print("sendHDTransaction Error: \(error)")
                completion(nil, error)
                
                return
            }
            
            if dict!["code"] as! Int == 200 {
                completion("good", nil)
            } else {
                completion(nil, nil)
            }
        }
    }
    
//    func createEtherTx(binaryData: inout BinaryData, wallet: UserWalletRLM, sendAddress: String, sendAmountString: String, gasPriceString: String, gasLimitString: String) {
//        let blockchain = BlockchainType.create(wallet: wallet)
//        
//        let localBlockchainType = self.localBlockchainType(blockchainType: blockchain)
//        let localWalletID = self.localWalletID(blockchainType: blockchain, walletID: wallet.walletID.uint32Value)
//        let localAddressID = self.localAddressID(blockchainType: blockchain, walletID: wallet.walletID.uint32Value, addressID: wallet.addressID.uint32Value)
//        
//        
//        let addressData = self.coreLibManager.createAddress(blockchainType: localBlockchainType, walletID: localWalletID, addressID: localAddressID, binaryData: &binaryData)
//        
//        let tx = self.coreLibManager.createEtherTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
//                                                           sendAddress: sendAddress,
//                                                           sendAmountString: sendAmountString,
//                                                           nonce: wallet.ethWallet!.nonce.intValue,
//                                                           balanceAmount: wallet.availableAmount.stringValue,
//                                                           ethereumChainID: UInt32(4), //RINKEBY
//                                                           gasPrice: gasPriceString,
//                                                           gasLimit: gasLimitString)
//        
////        tx
//    }
    
    func privateKeyString(blockchain: BlockchainType, walletID: UInt32, addressID: UInt32, binaryData: inout BinaryData) -> String {
        let localBlockchainType = self.localBlockchainType(blockchainType: blockchain)
        let localWalletID = self.localWalletID(blockchainType: blockchain, walletID: walletID)
        let localAddressID = self.localAddressID(blockchainType: blockchain, walletID: walletID, addressID: addressID)
        
        return coreLibManager.privateKeyString(blockchain: localBlockchainType, walletID: localWalletID, addressID: localAddressID, binaryData: &binaryData)
    }
}

extension CoreLibETHManager {
    func makeTX(from json: Dictionary<String, Any>) -> Result<String, String> {
        if let theJSONData = try? JSONSerialization.data(withJSONObject: json,
                                                         options: []) {
            let theJSONText = String(data: theJSONData, encoding: .ascii)
            print("JSON string = \(theJSONText!)")
            
            let rawTxInfo = coreLibManager.createEtherTx(from: theJSONText!)
            
            if rawTxInfo.isTransactionCorrect {
                if let data = rawTxInfo.message.data(using: .utf8) {
                    let info = try! JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    if let tx = info?["transaction"] as? Dictionary<String, String> {
                        if let serialized = tx["serialized"] {
                            return Result.success(serialized)
                        } else {
                            return Result.failure("cannot get serialized")
                        }
                    } else {
                        return Result.failure("cannot get transaction")
                    }
                } else {
                    return Result.failure("cannot convert to data")
                }
            } else {
                return Result.failure(rawTxInfo.message)
            }
        }
        
        return Result.failure("Error")
    }
    
    func createETHTransaction(wallet: UserWalletRLM,
                              sendAmountString: String,
                              destinationAddress: String,
                              gasPriceAmountString: String,
                              gasLimitAmountString: String,
                              payload: String = "") -> (isTransactionCorrect: Bool, message: String) {
        let info = DataManager.shared.privateInfo(for: wallet)
        if info == nil {
            return (false, "Error")
        }
        
        var txInfo = Dictionary<String, Any>()
        var accountDict = Dictionary<String, Any>()
        var builderDict = Dictionary<String, Any>()
        var payloadDict = Dictionary<String, Any>()
        var txDict = Dictionary<String, Any>()
        var feeDict = Dictionary<String, Any>()
        
        txInfo["blockchain"] =          wallet.blockchain.fullName
        txInfo["net_type"] =            wallet.blockchainType.net_type
        
        //account
        accountDict["type"] =           ACCOUNT_TYPE_DEFAULT.rawValue
        accountDict["private_key"] =    info!["privateKey"] as! String
        txInfo["account"] =             accountDict
        
        //builder
        builderDict["type"] =           "basic"
        //payload
        payloadDict["balance"] =                wallet.availableBalance.stringValue
        payloadDict["destination_amount"] =     sendAmountString
        payloadDict["destination_address"] =    destinationAddress
        if payload.isEmpty == false {
            payloadDict["payload"] =    payload
        }
        
        
        builderDict["payload"] =                payloadDict
        txInfo["builder"] =                     builderDict
        
        //transaction
        txDict["nonce"] =               wallet.ethWallet!.nonce
        feeDict["gas_price"] =          gasPriceAmountString
        feeDict["gas_limit"] =          gasLimitAmountString
        txDict["fee"] =                 feeDict
        txInfo["transaction"] =         txDict
        
        let rawTX = makeTX(from: txInfo)
        
        switch rawTX {
        case .success(let txString):
            return (true, txString)
        case .failure(let error):
            return (false, error)
        }
    }
    
    func createERC20TokenTransaction(wallet: UserWalletRLM,
                                     tokenWallet: UserWalletRLM,
                                     sendTokenAmountString: String,
                                     destinationAddress: String,
                                     gasPriceAmountString: String,
                                     gasLimitAmountString: String) -> (isTransactionCorrect: Bool, message: String) {
        let info = privateInfo(for: wallet)
        if info == nil {
            return (false, "Error")
        }
        
        var txInfo = Dictionary<String, Any>()
        var accountDict = Dictionary<String, Any>()
        var builderDict = Dictionary<String, Any>()
        var payloadDict = Dictionary<String, Any>()
        var txDict = Dictionary<String, Any>()
        var feeDict = Dictionary<String, Any>()
        
        txInfo["blockchain"] =          wallet.blockchain.fullName
        txInfo["net_type"] =            wallet.blockchainType.net_type
        
        //account
        accountDict["type"] =           ACCOUNT_TYPE_DEFAULT.rawValue
        accountDict["private_key"] =    info!["privateKey"] as! String
        txInfo["account"] =             accountDict
        
        //builder
        builderDict["type"] =           "erc20"
        builderDict["action"] =         "transfer"
        //payload
        payloadDict["balance_eth"] =            wallet.availableBalance.stringValue
        payloadDict["contract_address"] =       tokenWallet.address
        payloadDict["balance_token"] =          tokenWallet.ethWallet!.balance
        payloadDict["transfer_amount_token"] =  sendTokenAmountString
        payloadDict["destination_address"] =    destinationAddress
        builderDict["payload"] =                payloadDict
        txInfo["builder"] =                     builderDict
        
        //transaction
        txDict["nonce"] =               wallet.ethWallet!.nonce
        feeDict["gas_price"] =          gasPriceAmountString
        feeDict["gas_limit"] =          gasLimitAmountString
        txDict["fee"] =                 feeDict
        txInfo["transaction"] =         txDict
        
        let rawTX = makeTX(from: txInfo)
        
        switch rawTX {
        case .success(let txString):
            return (true, txString)
        case .failure(let error):
            return (false, error)
        }
    }
}

extension CoreLibInfoManager {
    func privateInfo(for wallet: UserWalletRLM) -> Dictionary<String, Any>? {
        if wallet.blockchain != BLOCKCHAIN_ETHEREUM {
            return nil
        }
        
        if wallet.isImported {
            if wallet.importedPrivateKey.isEmpty {
                return nil
            } else {
                switch createPublicInfo(blockchainType: wallet.blockchainType, privateKey: wallet.importedPrivateKey) {
                case .success(let info):
                    return info
                case .failure(_):
                    return nil
                }
            }
        } else if wallet.isMultiSig {
            return nil
        } else {
            var binData = realmManager.account!.binaryDataString.createBinaryData()!
            
            return createAddress(blockchainType: wallet.blockchainType, walletID: wallet.walletID.uint32Value, addressID: 0, binaryData: &binData)
        }
    }
    
    func metamaskWalletsInfoForRestore(seedPhrase: String, isMainnet: Bool) -> Parameters {
        var params = Parameters()
        
        params["currencyID"] = 60
        params["networkId"] = isMainnet ? ETHEREUM_CHAIN_ID_MAINNET.rawValue : ETHEREUM_CHAIN_ID_RINKEBY.rawValue
        
        params["addresses"] = generateMetamaskAddressesInfo(seedPhrase: seedPhrase, isMainnet: isMainnet)
        
        return params
    }
    
    func generateMetamaskAddressesInfo(seedPhrase: String, isMainnet: Bool) -> Array<Parameters> {
        var binData = coreLibManager.createSeedBinaryData(from: seedPhrase)!
        var addressesInfo = Array<Parameters>()
        let blockchainType = BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: Int(ETHEREUM_CHAIN_ID_MAINNET.rawValue))
        (0..<10).forEach {
            var addressInfo = Parameters()
            let info = coreLibManager.createAddress(blockchainType: blockchainType, walletID: 0, addressID: UInt32($0), binaryData: &binData)
            
            addressInfo["walletIndex"] = UInt32($0)
            addressInfo["addressIndex"] = 0
            addressInfo["address"] = info!["address"] ?? ""
            addressInfo["walletName"] = "Account " + "\($0 + 1)"
            
            addressesInfo.append(addressInfo)
        }
        
        return addressesInfo
    }
}

extension CoreLibPrivateKeyFixManager  {
    func checkWallets(_ wallets: List<UserWalletRLM>) -> [UserWalletRLM] {
        var convertedWallets = [UserWalletRLM]()
        
        guard DataManager.shared.shouldCheckWalletsPrivateKeys  else {
            return convertedWallets
        }
        
        for wallet in wallets {
            if (wallet.blockchain != BLOCKCHAIN_ETHEREUM || wallet.isImported || wallet.isMultiSig) && wallet.shouldFixPrivateKey == false {
                continue
            }
            
            var binaryData = realmManager.account!.binaryDataString.createBinaryData()!
            
            let addressData = createNewWallet(for: &binaryData, blockchain: wallet.blockchainType, walletID: wallet.walletID.uint32Value)
            
            if addressData == nil {
                continue
            }
            
            let address = addressData!["address"] as! String
            
            if address == wallet.address { //the good case
                continue
            }
            
            let newKeysData = coreLibManager.findPrivateKey(for: wallet.address, blockchainType: wallet.blockchainType, walletID: wallet.walletID.uint32Value, binaryData: &binaryData)
            
            if newKeysData == nil {
                continue
            }
            
            let convertedWallet = wallet
            convertedWallet.importedPrivateKey = newKeysData!["privateKey"] as! String
            convertedWallet.importedPublicKey = newKeysData!["publicKey"] as! String
            convertedWallet.brokenState = NSNumber(value: 1)
            
            convertedWallets.append(convertedWallet)
        }
        
        let convertedAddresses = convertedWallets.map { $0.address }
        
        convertToBroken(convertedAddresses) { print( $0) }
        
        return convertedWallets
    }
    
    func createWalletData(currencyID: NSNumber, networkID: NSNumber, walletID: NSNumber) -> Dictionary<String, Any> {
        var binaryData = realmManager.account!.binaryDataString.createBinaryData()!
        let blockchainType = BlockchainType(blockchain: Blockchain(rawValue: currencyID.uint32Value), net_type: networkID.intValue)
        
        let addressData = coreLibManager.createAddress(blockchainType: blockchainType,
                                             walletID: walletID.uint32Value,
                                             addressID: 0,
                                             binaryData: &binaryData)
        
        return addressData!
    }
}

extension MultisigManager {
    func createMultiSigWallet(wallet: UserWalletRLM,
                              creationPriceString: String,
                              gasPriceString: String,
                              gasLimitString: String,
                              owners: String,
                              confirmationsCount: Int) -> (isTransactionCorrect: Bool, message: String) {
        let info = privateInfo(for: wallet)
        if info == nil {
            return (false, "Error")
        }
        
        let factoryAddress = multisigFactory(for: wallet.blockchainType)
        
        if factoryAddress == nil || factoryAddress!.isEmpty {
            return (false, "Missed factory address")
        }
        
        var txInfo = Dictionary<String, Any>()
        var accountDict = Dictionary<String, Any>()
        var builderDict = Dictionary<String, Any>()
        var payloadDict = Dictionary<String, Any>()
        var txDict = Dictionary<String, Any>()
        var feeDict = Dictionary<String, Any>()
        
        txInfo["blockchain"] =          wallet.blockchain.fullName
        txInfo["net_type"] =            wallet.blockchainType.net_type
        
        //account
        accountDict["type"] =           ACCOUNT_TYPE_DEFAULT.rawValue
        accountDict["private_key"] =    info!["privateKey"] as! String
        txInfo["account"] =             accountDict
        
        //builder
        builderDict["type"] =           "multisig"
        builderDict["action"] =         "new_wallet"
        //payload
        payloadDict["balance"] =                wallet.availableBalance.stringValue
        payloadDict["price"] =                  creationPriceString
        payloadDict["factory_address"] =        factoryAddress!
        payloadDict["owners"] =                 owners
        payloadDict["confirmations"] =          confirmationsCount
        builderDict["payload"] =                payloadDict
        txInfo["builder"] =                     builderDict
        
        //transaction
        txDict["nonce"] =               wallet.ethWallet!.nonce
        feeDict["gas_price"] =          gasPriceString
        feeDict["gas_limit"] =          gasLimitString
        txDict["fee"] =                 feeDict
        txInfo["transaction"] =         txDict
        
        let rawTX = makeTX(from: txInfo)
        
        switch rawTX {
        case .success(let txString):
            return (true, txString)
        case .failure(let error):
            return (false, error)
        }
    }
    
    func createMultiSigTx(wallet: UserWalletRLM,
                          sendFromAddress: String,
                          sendAmountString: String,
                          sendToAddress: String,
                          msWalletBalance: String,
                          gasPriceString: String,
                          gasLimitString: String) -> (isTransactionCorrect: Bool, message: String) {
        let info = privateInfo(for: wallet)
        if info == nil {
            return (false, "Error")
        }
        
        var txInfo = Dictionary<String, Any>()
        var accountDict = Dictionary<String, Any>()
        var builderDict = Dictionary<String, Any>()
        var payloadDict = Dictionary<String, Any>()
        var txDict = Dictionary<String, Any>()
        var feeDict = Dictionary<String, Any>()
        
        txInfo["blockchain"] =          wallet.blockchain.fullName
        txInfo["net_type"] =            wallet.blockchainType.net_type
        
        //account
        accountDict["type"] =           ACCOUNT_TYPE_DEFAULT.rawValue
        accountDict["private_key"] =    info!["privateKey"] as! String
        txInfo["account"] =             accountDict
        
        //builder
        builderDict["type"] =           "multisig"
        builderDict["action"] =         "new_request"
        //payload
        payloadDict["balance"] =                msWalletBalance
        payloadDict["amount"] =                 sendAmountString
        payloadDict["wallet_address"] =         sendFromAddress
        payloadDict["dest_address"] =           sendToAddress
        builderDict["payload"] =                payloadDict
        txInfo["builder"] =                     builderDict
        
        //transaction
        txDict["nonce"] =               wallet.ethWallet!.nonce
        feeDict["gas_price"] =          gasPriceString
        feeDict["gas_limit"] =          gasLimitString
        txDict["fee"] =                 feeDict
        txInfo["transaction"] =         txDict
        
        let rawTX = makeTX(from: txInfo)
        
        switch rawTX {
        case .success(let txString):
            return (true, txString)
        case .failure(let error):
            return (false, error)
        }
    }
    
    func confirmMultiSigTx(wallet: UserWalletRLM,
                           sendFromAddress: String,
                           nonceMultiSigTx: Int,
                           gasPriceString: String,
                           gasLimitString: String) -> (isTransactionCorrect: Bool, message: String) {
        let info = privateInfo(for: wallet)
        if info == nil {
            return (false, "Error")
        }
        
        var txInfo = Dictionary<String, Any>()
        var accountDict = Dictionary<String, Any>()
        var builderDict = Dictionary<String, Any>()
        var payloadDict = Dictionary<String, Any>()
        var txDict = Dictionary<String, Any>()
        var feeDict = Dictionary<String, Any>()
        
        txInfo["blockchain"] =          wallet.blockchain.fullName
        txInfo["net_type"] =            wallet.blockchainType.net_type
        
        //account
        accountDict["type"] =           ACCOUNT_TYPE_DEFAULT.rawValue
        accountDict["private_key"] =    info!["privateKey"] as! String
        txInfo["account"] =             accountDict
        
        //builder
        builderDict["type"] =           "multisig"
        builderDict["action"] =         "request"
        //payload
        payloadDict["balance"] =                wallet.availableAmount.stringValue
        payloadDict["wallet_address"] =         sendFromAddress
        payloadDict["request_id"] =             nonceMultiSigTx
        payloadDict["action"] =                 "confirm"
        builderDict["payload"] =                payloadDict
        txInfo["builder"] =                     builderDict
        
        //transaction
        txDict["nonce"] =               wallet.ethWallet!.nonce
        feeDict["gas_price"] =          gasPriceString
        feeDict["gas_limit"] =          gasLimitString
        txDict["fee"] =                 feeDict
        txInfo["transaction"] =         txDict
        
        let rawTX = makeTX(from: txInfo)
        
        switch rawTX {
        case .success(let txString):
            return (true, txString)
        case .failure(let error):
            return (false, error)
        }

    }

//    func createMultiSigWallet(binaryData: inout BinaryData,
//                              wallet: UserWalletRLM,
//                              creationPriceString: String,
//                              gasPriceString: String,
//                              gasLimitString: String,
//                              owners: String,
//                              confirmationsCount: UInt32) -> (message: String, isTransactionCorrect: Bool) {
//        let blockchainType = BlockchainType.create(wallet: wallet)
//        var pointer : UnsafeMutablePointer<OpaquePointer?>?
//        if wallet.isImported {
//            let blockchainType = wallet.blockchainType
//            let privatekey = wallet.importedPrivateKey
//            let walletInfo = DataManager.shared.coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: privatekey)
//            switch walletInfo {
//            case .success(let value):
//                pointer = value["pointer"] as? UnsafeMutablePointer<OpaquePointer?>
//            case .failure(let error):
//                print(error)
//                
//                return (error, false)
//            }
//        } else {
//            let addressData = coreLibManager.createAddress(blockchainType: blockchainType, walletID: wallet.walletID.uint32Value, addressID: wallet.addressID.uint32Value, binaryData: &binaryData)
//            pointer = addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>
//        }
//        let factoryAddress = multisigFactory(for: blockchainType)
//        
//        if factoryAddress == nil || factoryAddress!.isEmpty {
//            return ("Missed factory address", false)
//        }
//        
//        let multiSigWalletCreationInfo = coreLibManager.createMutiSigWallet(addressPointer: pointer!,
//                                                                            creationPriceString: creationPriceString,
//                                                                            factoryAddress: factoryAddress!,
//                                                                            owners: owners,
//                                                                            confirmationsCount: confirmationsCount,
//                                                                            nonce: wallet.ethWallet!.nonce.intValue,
//                                                                            balanceAmountString: wallet.availableAmount.stringValue,
//                                                                            gasPriceString: gasPriceString,
//                                                                            gasLimitString: gasLimitString)
//        
//        return multiSigWalletCreationInfo
//    }
    
//    func createMultiSigTx(binaryData: inout BinaryData,
//                          wallet: UserWalletRLM,
//                          sendFromAddress: String,
//                          sendAmountString: String,
//                          sendToAddress: String,
//                          msWalletBalance: String,
//                          gasPriceString: String,
//                          gasLimitString: String) -> (message: String, isTransactionCorrect: Bool) {
//        let blockchainType = BlockchainType.create(wallet: wallet)
//
//        var addressData: Dictionary<String, Any>?
//
//        if wallet.isImported {
//            let accountDataResult = coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: wallet.importedPrivateKey)
//
//            switch accountDataResult {
//            case .failure(let error):
//                break
//            case .success(let accountData):
//                addressData = ["addressPointer" : accountData["pointer"] as? UnsafeMutablePointer<OpaquePointer?>]
//                break
//            }
//        } else {
//            addressData = coreLibManager.createAddress(blockchainType: blockchainType,
//                                                       walletID: wallet.walletID.uint32Value,
//                                                       addressID: wallet.addressID.uint32Value,
//                                                       binaryData: &binaryData)
//        }
//
//        if addressData == nil {
//            return ("Error", false)
//        }
//
//        let multiSigTxCreationInfo = coreLibManager.createMultiSigTx(addressPointer:    addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
//                                                                     sendFromAddress:   sendFromAddress,
//                                                                     sendAmountString:  sendAmountString,
//                                                                     sendToAddress:     sendToAddress,
//                                                                     nonce:             wallet.ethWallet!.nonce.intValue,
//                                                                     balanceAmountString: msWalletBalance,
//                                                                     gasPriceString:    gasPriceString,
//                                                                     gasLimitString:    gasLimitString)
//
//        return multiSigTxCreationInfo
//    }
    
//    func confirmMultiSigTx(binaryData: inout BinaryData,
//                           wallet: UserWalletRLM,
//                           balanceAmountString: String,
//                           sendFromAddress: String,
//                           nonce: Int,
//                           nonceMultiSigTx: Int,
//                           gasPriceString: String,
//                           gasLimitString: String) -> (message: String, isTransactionCorrect: Bool) {
//        let blockchainType = BlockchainType.create(wallet: wallet)
//
//        var addressData: Dictionary<String, Any>?
//
////        if wallet.isImported {
//        if wallet.isImportedForPrimaryKey {
//            let accountDataResult = coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: wallet.importedPrivateKey)
//
//            switch accountDataResult {
//            case .failure(let error):
//                break
//            case .success(let accountData):
//                addressData = ["addressPointer" : accountData["pointer"] as? UnsafeMutablePointer<OpaquePointer?>]
//                break
//            }
//        } else {
//            addressData = coreLibManager.createAddress(blockchainType: blockchainType,
//                                                           walletID: wallet.walletID.uint32Value,
//                                                           addressID: wallet.addressID.uint32Value,
//                                                           binaryData: &binaryData)
//        }
//
//        if addressData == nil {
//            return ("Error", false)
//        }
//
//        let multiSigTxConfirmInfo = coreLibManager.confirmMultiSigTx(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
//                                                                     sendFromAddress: sendFromAddress,
//                                                                     nonce: nonce,
//                                                                     nonceMultiSigTx: nonceMultiSigTx,
//                                                                     balanceAmountString: balanceAmountString,
//                                                                     gasPriceString: gasPriceString,
//                                                                     gasLimitString: gasLimitString)
//
//        return multiSigTxConfirmInfo
//    }
}
