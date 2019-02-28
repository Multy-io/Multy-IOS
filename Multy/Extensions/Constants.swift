//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

private typealias LocalizeDelegate = Constants

struct Constants {
    
    //Assets screen
    struct AssetsScreen {
        static let createWalletString = "Create wallet"
        static let backupButtonHeight = CGFloat(44)
        static let backupAssetsOffset = CGFloat(25)
        static let leadingAndTrailingOffset = CGFloat(16)
    }
    
    struct ETHWalletScreen {
        static let topCellHeight = CGFloat(331)
        static let blockedCellDifference = CGFloat(60) // difference in table cell sizes in case existing/non existing blocked amount on wallet
        static let collectionCellDifference = CGFloat(137) // difference in sizes btw table cell and collection cell
    }
    
    //StoryboardStrings
    struct Storyboard {
        //Assets
        static let createWalletVCSegueID = "createWalletVC"
        static let contactVCSegueID = "contactVC"
        static let waitingMembersSettingsVCSegueID = "waitingMembersSettings"
        static let toExchangeSegueID = "toExchangeSegue"
    }
    
    struct UserDefaults {
        //Config constants
        static let apiVersionKey =         "apiVersion"
        static let hardVersionKey =        "hardVersion"
        static let softVersionKey =        "softVersion"
        static let serverTimeKey =         "serverTime"
        static let stocksKey =             "stocks"
        static let btcDonationAddressesKey =  "donationAddresses"
    }
    
    struct DataManager {
        static let btcTestnetDonationAddress =  "mnUtMQcs3s8kSkSRXpREVtJamgUCWpcFj4"
        
        static let availableBlockchains = [
            BlockchainType.create(currencyID: BLOCKCHAIN_BITCOIN.rawValue, netType: BITCOIN_NET_TYPE_MAINNET.rawValue),
            BlockchainType.create(currencyID: BLOCKCHAIN_BITCOIN.rawValue, netType: BITCOIN_NET_TYPE_TESTNET.rawValue),
            BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_MAINNET.rawValue)),
            BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_RINKEBY.rawValue)),
        ]
        
        static let availableMultisigBlockchains = [BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_MAINNET.rawValue)),
                                                   BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_RINKEBY.rawValue))]
        
        static let donationBlockchains = [
//            BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM.rawValue, netType: UInt32(ETHEREUM_CHAIN_ID_MAINNET.rawValue)),
//            BlockchainType.create(currencyID: BLOCKCHAIN_BITCOIN_LIGHTNING.rawValue,netType: 0),
//            BlockchainType.create(currencyID: BLOCKCHAIN_GOLOS.rawValue,            netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_STEEM.rawValue,            netType: 0),
//            BlockchainType.create(currencyID: BLOCKCHAIN_BITSHARES.rawValue,        netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_BITCOIN_CASH.rawValue,     netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_LITECOIN.rawValue,         netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_DASH.rawValue,             netType: 0),
            BlockchainType.create(currencyID: BLOCKCHAIN_ETHEREUM_CLASSIC.rawValue, netType: 0),
//            BlockchainType.create(currencyID: BLOCKCHAIN_ERC20.rawValue,            netType: 0),
        ]
        
        struct RealmManager {
            static let leastSchemaVersionAfterCoreLibPrivateKeyFix = 31
        }
    }
    
    struct BigIntSwift {
        static let oneETHInWeiKey = BigInt("1000000000000000000") // 1 ETH = 10^18 Wei
        static let oneHundredFinneyKey = BigInt("10000000000000000") // 10^{-2} ETH
        
        static let oneBTCInSatoshiKey = BigInt("100000000") // 1 BTC = 10^8 Satoshi
        static let oneCentiBitcoinInSatoshiKey = BigInt("1000000") // 10^{-2} BTC
    }
    
    struct BlockchainString {
        static let bitcoinKey = "bitcoin"
        static let ethereumKey = "ethereum"
    }
    
    struct CustomFee {
        static let defaultBTCCustomFeeKey = BigInt("2")
        static let defaultETHCustomFeeKey = BigInt("1") // in GWei
    }
    
    struct Infura {
        static let mainnetETHUrl = "https://mainnet.infura.io/v3/78ae782ed28e48c0b3f74ca69c4f7ca8"
        static let testnetETHUrl = "https://rinkeby.infura.io/v3/78ae782ed28e48c0b3f74ca69c4f7ca8"
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}

enum DefaultFeeRates: Hashable {
    case eth
    case btc
    
    public var feeValue: NSDictionary {
        switch self {
        case .eth:
            return ["VeryFast" : 32,
                    "Fast" : 16,
                    "Medium" : 8,
                    "Slow" : 4,
                    "VerySlow" : 2,
            ]
        case .btc:
            return ["VeryFast" : 5,
                    "Fast" : 4,
                    "Medium" : 3,
                    "Slow" : 2,
                    "VerySlow" : 1,
            ]
        }
    }
    
    static func feeValues(for blockchain: Blockchain) -> NSDictionary {
        switch blockchain {
        case BLOCKCHAIN_BITCOIN:
            return DefaultFeeRates.btc.feeValue
        case BLOCKCHAIN_ETHEREUM:
            return DefaultFeeRates.eth.feeValue
        default:
            return NSDictionary()
        }
    }
}

let minBTCDonationAmount = 0.0001

let defaultDelimeter = "." as Character

let screenSize = UIScreen.main.bounds
let screenWidth = UIScreen.main.bounds.size.width
let screenHeight = UIScreen.main.bounds.size.height

//Devices Heights
let heightOfXSMax    : CGFloat = 896.0
let heightOfX        : CGFloat = 812.0
let heightOfPlus     : CGFloat = 736.0
let heightOfStandard : CGFloat = 667.0
let heightOfFive     : CGFloat = 568.0
let heightOfiPad     : CGFloat = 480.0
//


let brickColorSelectedGreen = UIColor(redInt: 95, greenInt: 204, blueInt: 125, alpha: 1.0)
let brickColorUnSelected =  UIColor(redInt: 239, greenInt: 239, blueInt: 244, alpha: 1.0)
let brickColorSelectedBlue = UIColor(redInt: 3, greenInt: 122, blueInt: 255, alpha: 1.0)
let brickColorBorderGreen = UIColor(redInt: 95, greenInt: 204, blueInt: 125, alpha: 1.0).cgColor
let brickColorBorderBlue = UIColor(redInt: 3, greenInt: 122, blueInt: 255, alpha: 1.0).cgColor

let widthOfSmall    : CGFloat = 320
let widthOfNormal   : CGFloat = 375
let widthOfBig      : CGFloat = 414


let infoPlist = Bundle.main.infoDictionary!

//createWallet, WalletSettingd
let maxNameLength = 25

let nanosecondsInOneSecond = 1000000000.0

let statuses = ["createdTx", "fromSocketTx", "incoming in mempool", "spend in mempool", "incoming in block", "spend in block", "in block confirmed", "rejected block"]

var isNeedToAutorise = false
var isViewPresented = false

var isDebug: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}

var transactionEmptyCount: Int {
    return screenHeight == heightOfX || screenHeight == heightOfXSMax ? 13 : 10
}

var tokenEmptyCount: Int {
    return screenHeight == heightOfX || screenHeight == heightOfXSMax ? 13 : 10
}

func sync(lock: NSObject, closure: @escaping () -> Void) {
    objc_sync_enter(lock)
        closure()
    objc_sync_exit(lock)
}

func convertSatoshiToBTCString(sum: UInt64) -> String {
    return (Double(sum) / pow(10, 8)).fixedFraction(digits: 8) + " BTC"
}

func convertSatoshiToBTC(sum: Double) -> String {
    return (sum / pow(10, 8)).fixedFraction(digits: 8)
}

func convertBTCStringToSatoshi(sum: String) -> UInt64 {
    return UInt64(sum.toStringWithZeroes(precision: 8))!
}

func convertBTCToSatoshi(sum: String) -> Double {
    return sum.convertStringWithCommaToDouble() * pow(10, 8)
}

func shakeView(viewForShake: UIView) {
    let animation = CABasicAnimation(keyPath: "position")
    animation.duration = 0.07
    animation.repeatCount = 4
    animation.autoreverses = true
    animation.fromValue = NSValue(cgPoint: CGPoint(x: viewForShake.center.x - 10, y: viewForShake.center.y))
    animation.toValue = NSValue(cgPoint: CGPoint(x: viewForShake.center.x + 10, y: viewForShake.center.y))
    
    viewForShake.layer.add(animation, forKey: "position")
//    self.viewWithCircles.layer.add(animation, forKey: "position")
}

let HUDFrame = CGRect(x: screenWidth / 2 - 70,   // width / 2
                      y: screenHeight / 2 - 60,  // height / 2
                      width: 145,
                      height: 120)

let idOfInapps = ["io.multy.addingActivity5", "io.multy.addingCharts5", "io.multy.addingContacts5",
                  "io.multy.addingDash5", "io.multy.addingEthereumClassic5", "io.multy.addingExchange5",
                  "io.multy.exchangeStocks", "io.multy.importWallet5", "io.multy.addingLitecoin5",
                  "io.multy.addingPortfolio5", "io.multy.addingSteemit5", "io.multy.wirelessScan5",
                  "io.multy.addingBCH5", "io.multy.estimationCurrencies5", "io.multy.addingEthereum5"]

let idOfInapps50 = ["io.multy.addingActivity50", "io.multy.addingCharts50", "io.multy.addingContacts50",
                  "io.multy.addingDash50", "io.multy.addingEthereumClassic50", "io.multy.addingExchange50",
                  "io.multy.exchangeStocks50", "io.multy.importWallet50", "io.multy.addingLitecoin50",
                  "io.multy.addingPortfolio50", "io.multy.addingSteemit50", "io.multy.wirelessScan50",
                  "io.multy.addingBCH50", "io.multy.estimationCurrencie50", "io.multy.addingEthereum50"]

enum WalletType : Int {
    case
        Created =       0,
        Multisig =      1,
        Imported =      2
}

enum TxStatus : Int {
    case
        Rejected =                   0,
        MempoolIncoming =            1,
        BlockIncoming =              2,
        MempoolOutcoming =           3,
        BlockOutcoming =             4,
        BlockConfirmedIncoming =     5,
        BlockConfirmedOutcoming =    6,
        BlockMethodInvocationFail =  7,
        RejectedIncoming =           8,
        RejectedOutgoing =           9
}

enum SocketMessageType : Int {
    case
        multisigJoin =              1,
        multisigLeave =             2,
        multisigDelete =            3,
        multisigKick =              4,
        multisigCheck =             5,
        multisigView =              6,
        multisigDecline =           7,
        multisigWalletDeploy =      8,
        multisigTxPaymentRequest =  9,
        multisigTxIncoming =        10,
        multisigTxConfirm =         11,
        multisigTxRevoke =          12,
        resyncCompleted =           13
}

enum Result<Value, Error: StringProtocol> {
    case success(Value)
    case failure(Error)
}

enum MultiSigWalletStatus: Int {
    case
        multisigStatusWaitingForJoin =  1,
        multisigStatusAllJoined =       2,
        multisigStatusDeployPending =   3,
        multisigStatusRejected =        4,
        multisigStatusDeployed =        5
}

enum MultisigOwnerTxStatus: Int {
    case
    msOwnerStatusWaiting   = 0,
    msOwnerStatusSeen      = 1,
    msOwnerStatusConfirmed = 2,
    msOwnerStatusDeclined  = 3
}

let minSatoshiInWalletForDonate: UInt64 = 10000 //10k minimun sum in wallet for available donation
let minSatoshiToDonate: UInt64          = 5000  //5k minimum sum to donate

let plainTxGasLimit : UInt64 = 42000
let plainERC20TxGasLimit : UInt64 = 500_000
let exchangeERC20TxGasLimit : UInt64 = 250_000
let minimumAmountForMakeEthTX = BigInt("\(900_000_000_000_000)") // == 10 cent 16.10.2018

//
let shortURL = "api.multy.io"
let apiUrl = "https://\(shortURL)/"
let socketUrl = "wss://\(shortURL)/"

//TEST
//let shortURL = "test.multy.io"
//let apiUrl = "http://\(shortURL)/"
//let socketUrl = "ws://\(shortURL)/"

//dev
//let shortURL = "dev.multy.io"
//let apiUrl = "http://\(shortURL)/"
//let socketUrl = "ws://\(shortURL)/"

//stage
//let shortURL = "stage.multy.io"
//let apiUrl = "http://\(shortURL)/"
//let socketUrl = "ws://\(shortURL)/"

//PASHA
//let shortURL = "192.168.31.112"
//let apiUrl = "http://\(shortURL):6778/"
//let socketUrl = "ws://\(shortURL):6780/"

// Bluetooth
let BluetoothSettingsURL_iOS9 = "prefs:root=Bluetooth"
let BluetoothSettingsURL_iOS10 = "App-Prefs:root=Bluetooth"

let inviteCodeCount = 45

var currentStatusStyle = UIStatusBarStyle.default
var isServerConnectionExist = true
let exchangeCourseDefault : Double = 1.0
let dappDLTitle = "Dragonereum"
let magicReceiveDL = "magicReceive"
let socketManagerStatusChangedNotificationName = "socketManagerStatusChangedNotification"
