//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

//usable properties as String - to avoid possible issues
enum HistoryProperty: String {
    case mempoolTime, txId, walletPrimaryKey
}

class HistoryRLM: Object {
    @objc dynamic var addresses = String()
    @objc dynamic var blockHeight = Int()
    @objc dynamic var blockTime = Date()
    @objc dynamic var fiatCourseExchange = Double()
    @objc dynamic var txFee: NSNumber = 0
    @objc dynamic var txHash = String()
    @objc dynamic var txId = String()
    var txInputs = List<TxHistoryRLM>()
    @objc dynamic var txOutAmount: NSNumber = 0
    @objc dynamic var txOutAmountString = String()
    
    @objc dynamic var gasLimit: NSNumber = 0
    @objc dynamic var gasPrice: NSNumber = 0
    
    @objc dynamic var txOutId = Int()
    var txOutputs = List<TxHistoryRLM>()
    @objc dynamic var txOutScript = String()
    @objc dynamic var txStatus = NSNumber(value: 0)
    @objc dynamic var walletIndex = NSNumber(value: 0)
    
    @objc dynamic var mempoolTime = Date()
    @objc dynamic var confirmations = Int()
    
    var addressesArray: [String] {
        return addresses.components(separatedBy: " ")
    }
    var exchangeRates = List<StockExchangeRateRLM>()
    var walletInput = List<UserWalletRLM>()
    var walletOutput = List<UserWalletRLM>()
    
    @objc dynamic var nonce = NSNumber(value: 0)
    @objc dynamic var walletPrimaryKey = String()
    @objc dynamic var multisig : MultisigTransactionRLM? = nil
    
    override static func ignoredProperties() -> [String] {
        return ["addressesArray"]
    }
    
    func fee(for blockchain: Blockchain) -> BigInt {
        var result = BigInt.zero()
        switch blockchain {
        case BLOCKCHAIN_BITCOIN:
            result = BigInt("\(txFee)")
            break
        case BLOCKCHAIN_ETHEREUM:
            result = (BigInt("\(gasLimit)") * BigInt("\(gasPrice)"))
            break
            
        default:
            break
        }
        
        return result
    }
    
    public class func initWithArray(historyArr: NSArray, for id: String) -> [HistoryRLM] {
        var history = [HistoryRLM]()
        
        for obj in historyArr {
            let histElement = HistoryRLM.initWithInfo(historyDict: obj as! NSDictionary, for: id)
            history.append(histElement)
        }
        
        return history
    }
    
    public class func initWithInfo(historyDict: NSDictionary, for id: String) -> HistoryRLM {
        let hist = HistoryRLM()
        
        hist.walletPrimaryKey = id
        
        if let addresses = historyDict["addresses"] {
            hist.addresses = (addresses as! NSArray).componentsJoined(by: " ")
        }
        
        if let blockheight = historyDict["blockheight"] {
            hist.blockHeight = blockheight as! Int
        }
        
        if let confirmations = historyDict["confirmations"] as? Int {
            hist.confirmations = confirmations
        }
        
        if let blocktime = historyDict["blocktime"] as? TimeInterval {
            hist.blockTime = NSDate(timeIntervalSince1970: blocktime) as Date
            
            // in some cases mempool time equals 1 January 1970
            if hist.blockTime.timeIntervalSince1970 == 0 || hist.blockTime.timeIntervalSince1970 == -1 {
                hist.mempoolTime = Date()
            } else {
                hist.mempoolTime = hist.blockTime
            }
        }
        
        if hist.blockHeight == -1 {
            hist.blockTime = Date()
        }
        
        if let txfee = historyDict["txfee"] {
            hist.txFee = txfee as! NSNumber
        }
        
        if let txhash = historyDict["txhash"] {
            hist.txHash = txhash as! String
        }
        
//        if let txid = historyDict["txid"] {
//            hist.txId = txid as! String
//        }
        
        hist.txId = hist.txHash + ":" + id
        
        if let txinputs = historyDict["txinputs"] {
            hist.txInputs = TxHistoryRLM.initWithArray(txHistoryArr: txinputs as! NSArray)
        }
        
        if let rates = historyDict["stockexchangerate"] as? NSArray {
            hist.exchangeRates = StockExchangeRateRLM.initWithArray(stockArray: rates)
            // BTC and ETH // FIXME: fix it later
            if hist.exchangeRates.count > 0 {
                if hist.txInputs.count > 0 {
                    hist.fiatCourseExchange = hist.exchangeRates.first!.btc2usd
                } else {
                    hist.fiatCourseExchange = hist.exchangeRates.first!.eth2usd
                }
            }
        }

        if let txoutamount = historyDict["txoutamount"] as? NSNumber {
            hist.txOutAmount = txoutamount
        } else if let txOutAmountString = historyDict["txoutamount"] as? String {
            hist.txOutAmountString = txOutAmountString == "" ? "0" : txOutAmountString
        }
        
        if let gasPrice = historyDict["gasprice"] as? NSNumber {
            hist.gasPrice = gasPrice
        }
        
        if let gasLimit = historyDict["gaslimit"] as? NSNumber {
            hist.gasLimit = gasLimit
        }
        
        if let txoutid = historyDict["txoutid"] {
            hist.txOutId = txoutid as! Int
        }
        
        if let txoutputs = historyDict["txoutputs"] {
            hist.txOutputs = TxHistoryRLM.initWithArray(txHistoryArr: txoutputs as! NSArray)
        }

        if let txoutscript = historyDict["txoutscript"] {
            hist.txOutScript = txoutscript as! String
        }
        
        if let txstatus = historyDict["txstatus"] {
            hist.txStatus = txstatus as! NSNumber
        }
        
        //FIXME: add more parameters
        if let walletindex = historyDict["walletindex"] {
            hist.walletIndex = walletindex as! NSNumber
        }
        
        if let walletsinput = historyDict["walletsinput"] as? NSArray {
            hist.walletInput = UserWalletRLM.initWithArray(walletsInfo: walletsinput)
        }
        
        if let walletOutput = historyDict["walletsoutput"] as? NSArray {
            hist.walletOutput = UserWalletRLM.initWithArray(walletsInfo: walletOutput)
        }
        
        //ETH part
        if let fromAddress = historyDict["from"] as? String {
            hist.addresses = hist.addresses.isEmpty ? fromAddress : hist.addresses + " " + fromAddress
        }
        
        if let destinationAddress = historyDict["to"] as? String {
            hist.addresses = hist.addresses.isEmpty ? destinationAddress : hist.addresses + " " + destinationAddress
        }
        
        if let nonce = historyDict["nonce"] as? Int {
            hist.nonce = NSNumber(value: nonce)
        }
        
        if let multisig = historyDict["multisig"] as? NSDictionary {
            hist.multisig = MultisigTransactionRLM.initWithInfo(multisigTxDict: multisig)
        }
        
        return hist
    }
    
    override class func primaryKey() -> String {
        return HistoryProperty.txId.rawValue
    }
    
    var primaryKey: String {
        return txId
    }
    
    var isIncoming: Bool {
        return txStatus.intValue == TxStatus.MempoolIncoming.rawValue || txStatus.intValue == TxStatus.BlockIncoming.rawValue || txStatus.intValue == TxStatus.BlockConfirmedIncoming.rawValue
    }
    
    var isOutcoming: Bool {
        return txStatus.intValue == TxStatus.MempoolOutcoming.rawValue || txStatus.intValue == TxStatus.BlockOutcoming.rawValue || txStatus.intValue == TxStatus.BlockConfirmedOutcoming.rawValue
    }
    
    var isRejected: Bool {
        return txStatus.intValue == TxStatus.Rejected.rawValue || txStatus.intValue == TxStatus.BlockMethodInvocationFail.rawValue
    }
    
    var isPending: Bool {
        return txStatus.intValue == TxStatus.MempoolIncoming.rawValue || txStatus.intValue == TxStatus.MempoolOutcoming.rawValue
    }
    
    func getDonationTxOutput(address: String) -> TxHistoryRLM? {
        for output in self.txOutputs {
            if output.address == address {
                return output
            }
        }
        
        return nil
    }
}
