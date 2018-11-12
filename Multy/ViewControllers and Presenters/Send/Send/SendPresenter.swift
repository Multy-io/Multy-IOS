//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift

private typealias CreateTransactionDelegate = SendPresenter

class SendPresenter: NSObject {
    var sendVC : SendViewController?
    
    var rawTransaction = String()
    var rawTransactionEstimation = 0.0
    var rawTransactionBigIntEstimation = BigInt.zero()
    
    var isSocketInitiateUpdating = false
    var isWalletAnalyticsSent = false
    
    var walletsArr = Array<UserWalletRLM>() {
        didSet {
            filterArray()
        }
    }
    var linkedWallet : UserWalletRLM?
    var feeRate = "1"
    var submitEstimation = "\(400_000)"
    
    var filteredWalletArray = Array<UserWalletRLM>() {
        didSet {
            if isWalletAnalyticsSent == false {
                isWalletAnalyticsSent = true
                sendVC?.sendAnalyticsEvent(screenName: KFSendScreen, eventName: KFWalletsCount + "\(filteredWalletArray.count)")
            }
            
            if filteredWalletArray.count == 0 {
                selectedWalletIndex = nil
            } else {
                if selectedWalletIndex == nil {
                    selectedWalletIndex = 0
                } else {
                    if selectedWalletIndex! >= filteredWalletArray.count {
                        selectedWalletIndex = filteredWalletArray.count - 1
                    } else {
                        selectedWalletIndex = selectedWalletIndex!
                    }
                }
                
                sendVC?.scrollToWallet(selectedWalletIndex!)
            }
            
            sendVC?.updateUI()
        }
    }
    
    var selectedWalletIndex : Int? {
        didSet {
            if selectedWalletIndex != oldValue {
                self.createTransactionDTO()
                
                self.sendVC?.updateUI()
            }
        }
    }
    
    var activeRequestsArr = [PaymentRequest]() {
        didSet {
            if activeRequestsArr.count == 0 {
                selectedActiveRequestIndex = nil
            } else {
                if selectedActiveRequestIndex == nil {
                    selectedActiveRequestIndex = 0
                } else if selectedActiveRequestIndex! >= activeRequestsArr.count {
                    selectedActiveRequestIndex = activeRequestsArr.count - 1
                } else {
                    selectedActiveRequestIndex = selectedActiveRequestIndex!
                }
                
                sendVC?.scrollToRequest(selectedActiveRequestIndex!)
            }
        }
    }
    
    var selectedActiveRequestIndex : Int? {
        didSet {
            filterArray()
            
            if selectedActiveRequestIndex != oldValue {
                self.createTransactionDTO()
                
                self.sendVC?.updateUI()
            }
        }
    }
    
    var isSendingAvailable : Bool {
        get {
            var result = false
            if selectedActiveRequestIndex != nil && selectedWalletIndex != nil {
//                let activeRequest = activeRequestsArr[selectedActiveRequestIndex!]
//                let wallet = walletsArr[selectedWalletIndex!]
                //FIXME:
                result = true
//                if wallet.sumInCrypto >= activeRequest.sendAmount.doubleValue {
//                    result = true
//                }
            }
            return result
        }
    }
    
    var estimationInfo: NSDictionary?
    
    var newUserCodes = [String]()
    
    var transaction : TransactionDTO?
    
    var receiveActiveRequestTimer : Timer?
    
    var blockActivityUpdating = false
    
    var checkNewUserCodesCounter = 0
    
//    var priceForSubmit = "\(1_000_000_000)"
    
    
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
    
    func filterArray() {
        if selectedActiveRequestIndex != nil  {
            let request = activeRequestsArr[selectedActiveRequestIndex!]
            
            let blockchainType = BlockchainType.create(currencyID: UInt32(request.currencyID), netType: UInt32(request.networkID))
            let sendAmount = request.sendAmount.stringWithDot.convertCryptoAmountStringToMinimalUnits(in: blockchainType.blockchain)
//            let address = request.sendAddress
            
            filteredWalletArray = walletsArr.filter {
                $0.blockchainType == blockchainType && $0.availableAmount > sendAmount
            }

//            filteredWalletArray = walletsArr.filter{ DataManager.shared.isAddressValid(address: address, for: $0).isValid && $0.availableAmount > sendAmount}
        } else {
            
            filteredWalletArray = walletsArr.filter {
                $0.availableAmount > BigInt.zero()
            }
        }
    }
    
    func viewControllerViewDidLoad() {
        let _ = BLEManager.shared
    }
    
    func viewControllerViewWillAppear() {
        viewWillAppear()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillResignActive(notification:)), name: Notification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationWillTerminate(notification:)), name: Notification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive(notification:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func viewWillAppear() {
        getWallets()
        
        blockActivityUpdating = false
        startSenderActivity()
        handleBluetoothReachability()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didDiscoverNewAd(notification:)), name: Notification.Name(didDiscoverNewAdvertisementNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangedBluetoothReachability(notification:)), name: Notification.Name(bluetoothReachabilityChangedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveNewRequests(notification:)), name: Notification.Name("newReceiver"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateWalletAfterSockets), name: NSNotification.Name("transactionUpdated"), object: nil)
    }
    
    func viewControllerViewWillDisappear() {
        viewWillDisappear()
        
        UIApplication.shared.isIdleTimerDisabled = false
        
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
    }
    
    func viewWillDisappear() {
        stopSenderActivity()
        blockActivityUpdating = true
        
        self.selectedWalletIndex = nil
        NotificationCenter.default.removeObserver(self, name: Notification.Name(didDiscoverNewAdvertisementNotificationName), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(bluetoothReachabilityChangedNotificationName), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("newReceiver"), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name("transactionUpdated"), object: nil)
    }
    
    func numberOfWallets() -> Int {
        return filteredWalletArray.count
    }
    
    func numberOfActiveRequests() -> Int {
        return activeRequestsArr.count
    }
    
    func getWallets() {
        DataManager.shared.getAccount { [unowned self] (acc, err) in
            if err == nil {
                // MARK: check this
                if acc != nil && acc!.wallets.count > 0 {
                    self.account = acc
                    self.walletsArr = acc!.wallets.sorted(by: {
                        $0.availableSumInCrypto > $1.availableSumInCrypto })
                }
            }
        }
    }
    
    func getWalletsVerbose() {
        DataManager.shared.getWalletsVerbose() { (walletsArrayFromApi, err) in
            if err != nil {
                return
            } else {
                let walletsArr = UserWalletRLM.initWithArray(walletsInfo: walletsArrayFromApi!)
                print("afterVerbose:rawdata: \(walletsArrayFromApi)")
                DataManager.shared.realmManager.updateWalletsInAcc(arrOfWallets: walletsArr, completion: { [weak self] (acc, err) in
                    if self != nil {
                        self!.account = acc
                        self!.walletsArr = acc!.wallets.sorted(by: {
                            $0.availableSumInCrypto > $1.availableSumInCrypto
                        })
                        self!.isSocketInitiateUpdating = false
                    }
                })
            }
        }
    }

    
    @objc func updateWalletAfterSockets() {
        if isSocketInitiateUpdating {
            return
        }
        
        if sendVC!.isVisible() == false {
            return
        }
        
        isSocketInitiateUpdating = true
        getWalletsVerbose()
    }
    
//    func getWalletsVerbose(completion: @escaping (_ flag: Bool) -> ()) {
//        DataManager.shared.getWalletsVerbose() {[unowned self] (walletsArrayFromApi, err) in
//            if err != nil {
//                return
//            } else {
//                let walletsArr = UserWalletRLM.initWithArray(walletsInfo: walletsArrayFromApi!)
//                print("afterVerbose:rawdata: \(walletsArrayFromApi)")
//                DataManager.shared.realmManager.updateWalletsInAcc(arrOfWallets: walletsArr, completion: { [unowned self] (acc, err) in
//                    self.account = acc
//                    
//                    if acc != nil && acc!.wallets.count > 0 {
//                        self.selectedWalletIndex = 0
//                        
//                        self.walletsArr = acc!.wallets.sorted(by: { $0.availableSumInCrypto > $1.availableSumInCrypto })
//                    }
//                    
//                    print("wallets: \(acc?.wallets)")
//                    completion(true)
//                })
//            }
//        }
//    }
    
    
    private func createTransactionDTO() {
        if isSendingAvailable && selectedWalletIndex != nil && filteredWalletArray.count > selectedWalletIndex!  {
            transaction = TransactionDTO()
            let request = activeRequestsArr[selectedActiveRequestIndex!]
            //FIXME:
            transaction!.sendAmount = request.sendAmount.doubleValue
            transaction!.sendAddress = request.sendAddress
            transaction!.choosenWallet = filteredWalletArray[selectedWalletIndex!]
        }
    }
    
    
    @objc private func didDiscoverNewAd(notification: Notification) {
        DispatchQueue.main.async {
            let newAdOriginID = notification.userInfo!["originID"] as! UUID
            if BLEManager.shared.receivedAds != nil {
                var newAd : Advertisement?
                for ad in BLEManager.shared.receivedAds! {
                    if ad.originID == newAdOriginID {
                        newAd = ad
                        print("Discovered new usercode \(ad.userCode)")
                        break
                    }
                }
                
                if newAd != nil {
                    self.newUserCodes.append(newAd!.userCode)
                }
            }
        }
    }
    
    func becomeSenderForUsersWithCodes(_ userCodes : [String]) {
        let uniqueUserCodes = Array(Set(userCodes))
        DataManager.shared.socketManager.becomeSender(nearIDs: uniqueUserCodes)
    }
    
    func startSenderActivity() {
        startSearchingActiveRequests()
    }
    
    func stopSenderActivity() {
        DataManager.shared.socketManager.stopSend()
        stopSearching()
        cleanRequests()
    }
        
    func handleBluetoothReachability() {
        switch BLEManager.shared.reachability {
        case .reachable, .unknown:
            if BLEManager.shared.reachability == .reachable {
                self.sendVC?.updateUIForBluetoothState(true)
                if !blockActivityUpdating {
                    startSenderActivity()
                }
            }
            
            break
            
        case .notReachable:
            self.sendVC?.updateUIForBluetoothState(false)
            if !blockActivityUpdating {
                stopSenderActivity()
            }
            break
        }
    }
    
    var addressData : Dictionary<String, Any>?
    var binaryData : BinaryData?
    var account = DataManager.shared.realmManager.account
    var feeAmount = BigInt("0")
    
    func createPreliminaryData(completion: @escaping (_ succeeded : Bool) -> ()) {
        let account = DataManager.shared.realmManager.account
        let core = DataManager.shared.coreLibManager
        let wallet = filteredWalletArray[selectedWalletIndex!]
        binaryData = account!.binaryDataString.createBinaryData()!
        
        
        addressData = core.createAddress(blockchainType:    wallet.blockchainType,
                                         walletID:      wallet.walletID.uint32Value,
                                         addressID:     wallet.changeAddressIndex,
                                         binaryData:    &binaryData!)
        
        if wallet.isMultiSig {
            DataManager.shared.estimation(for: wallet.address) { [unowned self] in
                switch $0 {
                case .success(let value):
                    let estimation = value["submitTransaction"] as? NSNumber
                    self.submitEstimation = estimation == nil ? "\(400_000)" : "\(estimation!)"
                    
                    DataManager.shared.getWallet(primaryKey: wallet.multisigWallet!.linkedWalletID) { [unowned self] in
                        switch $0 {
                        case .success(let wallet):
                            self.linkedWallet = wallet
                            completion(true)
                            break;
                        case .failure(let errorString):
                            completion(false)
                            print(errorString)
                            break;
                        }
                    }
                    
                    break
                case .failure(let error):
                    completion(false)
                    print(error)
                    break
                }
            }
        } else {
            completion(true)
        }
    }
    
    func getEstimation(for operation: String) -> String {
        let value = self.estimationInfo?[operation] as? NSNumber
        return value == nil ? "\(400_000)" : "\(value!)"
    }
    
    func prepareSending() {
        stopSearching()
    }
    
    @objc func cancelPrepareSending() {
        startSearchingActiveRequests()
    }
    
    func send() {
        guard let index = selectedWalletIndex else {
            self.sendVC?.updateUIWithSendResponse(success: false)
            
            return
        }
        
        createPreliminaryData { [unowned self] succeeded in
            if succeeded {
                self.createTransaction { [unowned self] (isCreated) in
                    let wallet = self.filteredWalletArray[index]
                    
                    if isCreated == false {
                        var message = self.rawTransaction
                        
                        if message.hasPrefix("BigInt value is not representable as") {
                            message = self.sendVC!.localize(string: Constants.youEnteredTooSmallAmountString)
                        } else if message.hasPrefix("Transaction is trying to spend more than available in inputs") {
                            message = self.sendVC!.localize(string: Constants.youTryingSpendMoreThenHaveString)
                        }
                        
                        //            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                        //            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in }))
                        //            sendVC!.present(alert, animated: true, completion: nil)
                        
                        //FIXME: show error message
                        self.sendVC?.updateUIWithSendResponse(success: false)
                        
                        return
                    }
                    
                    let newAddress = wallet.shouldCreateNewAddressAfterTransaction ? (self.transaction as! BTCTransactionDTO).newChangeAddress! : ""
                    
                    let newAddressParams = [
                        "walletindex"   : wallet.walletID.intValue,
                        "address"       : newAddress,
                        "addressindex"  : wallet.addresses.count,
                        "transaction"   : self.rawTransaction,
                        "ishd"          : wallet.shouldCreateNewAddressAfterTransaction
                        ] as [String : Any]
                    
                    let params = [
                        "currencyid": wallet.chain,
                        /*"JWT"       : jwtToken,*/
                        "networkid" : wallet.chainType,
                        "payload"   : newAddressParams
                        ] as [String : Any]
                    
                    
                    
                    DataManager.shared.sendHDTransaction(transactionParameters: params) { [unowned self] (dict, error) in
                        print("---------\(dict)")
                        
                        if error != nil {
                            self.sendVC!.sendAnalyticsEvent(screenName: self.className, eventName: (error! as NSError).userInfo.debugDescription)
                            self.sendVC!.updateUIWithSendResponse(success: false)
                            print("sendHDTransaction Error: \(error)")
                            self.sendVC!.sendAnalyticsEvent(screenName: KFSendScreen, eventName: KFTransactionError)
                            
                            return
                        }
                        
                        if dict!["code"] as! Int == 200 {
                            self.sendVC!.sendAnalyticsEvent(screenName: KFSendScreen, eventName: KFTransactionError)
                            self.sendVC?.updateUIWithSendResponse(success: true)
                        } else {
                            self.sendVC!.sendAnalyticsEvent(screenName: KFSendScreen, eventName: KFTransactionSuccess)
                            self.sendVC?.updateUIWithSendResponse(success: false)
                        }
                    }
                }
            }
        }
    }
    
    func createTransaction(completion: @escaping (_ feeRateDict: Bool) -> ()) {
        let wallet = filteredWalletArray[selectedWalletIndex!]
        
        getFeeRate(wallet.blockchainType) { [unowned self] (feeRate) in
            DispatchQueue.main.async {
                self.feeRate = feeRate
                print(feeRate)
                switch wallet.blockchainType.blockchain {
                case BLOCKCHAIN_BITCOIN:
                    completion(self.createBTCTransaction())
                case BLOCKCHAIN_ETHEREUM:
                    completion(self.createETHTransaction())
                default:
                    completion(false)
                }
            }
        }
    }
    
    func sendAnimationComplete() {
        self.sendVC?.updateUI()
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(cancelPrepareSending), userInfo: nil, repeats: false)
    }
    
    func cleanRequests() {
        self.activeRequestsArr.removeAll()
        self.selectedActiveRequestIndex = nil
        self.sendVC?.updateUI()
    }
    
    @objc private func didChangedBluetoothReachability(notification: Notification) {
        DispatchQueue.main.async {
            self.handleBluetoothReachability()
        }
    }
    
    @objc private func didReceiveNewRequests(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            let requests = notification.userInfo!["paymentRequests"] as! [PaymentRequest]
            
            if self != nil {
                self!.updateActiveRequests(requests)
                self!.sendVC?.updateUI()
            }
        }
    }
    
    func updateActiveRequests(_ newRequests : [PaymentRequest]) {
        var filteredRequestArray = newRequests.filter{ _ in true } //BigInt($0.sendAmount.convertCryptoAmountStringToMinimalUnits(in: BLOCKCHAIN_BITCOIN).stringValue) > Int64(0) }
        
        if selectedActiveRequestIndex != nil {
            // active request already exists
            let activeRequest = activeRequestsArr[selectedActiveRequestIndex!]
            let newActiveRequest = filteredRequestArray.filter{ $0.userCode == activeRequest.userCode}.first
            
            if newActiveRequest != nil {
                // there is new request with same userCode as userCode of active request
                let newActiveRequestIndex = filteredRequestArray.index(of: newActiveRequest!)
                if selectedActiveRequestIndex! > filteredRequestArray.count - 1 {
                    // replace new active request with last element in filtered requests
                    filteredRequestArray.remove(at: newActiveRequestIndex!)
                    filteredRequestArray.append(newActiveRequest!)
                } else {
                    // insert new active request at current index
                    filteredRequestArray.remove(at: newActiveRequestIndex!)
                    filteredRequestArray.insert(newActiveRequest!, at: selectedActiveRequestIndex!)
                }
            }
        }
        
        activeRequestsArr = filteredRequestArray
    }
    
    func addActivePaymentRequests(requests: [PaymentRequest]) {
        activeRequestsArr.append(contentsOf: requests)
        if numberOfActiveRequests() > 0 && selectedActiveRequestIndex == nil {
            selectedActiveRequestIndex = 0
        }
    }
    
    @objc private func applicationWillResignActive(notification: Notification) {
        viewWillDisappear()
    }
    
    @objc private func applicationWillTerminate(notification: Notification) {
        viewWillDisappear()
    }
    
    @objc private func applicationDidBecomeActive(notification: Notification) {
        viewWillAppear()
    }
    
    func indexForActiveRequst(_ request : PaymentRequest) -> Int? {
        for req in activeRequestsArr {
            if req.userCode == request.userCode {
                return activeRequestsArr.index(of: req)!
            }
        }
        return nil
    }
    
    @objc private func startSearchingActiveRequests() {
        BLEManager.shared.startScan()
        if receiveActiveRequestTimer == nil {
            receiveActiveRequestTimer = Timer.scheduledTimer(timeInterval: TimeInterval(1), target: self, selector: #selector(checkNewUserCodes), userInfo: nil, repeats: true)
            checkNewUserCodesCounter = 0
        }
    }
    
    @objc private func stopSearching() {
        BLEManager.shared.stopScan()
        if receiveActiveRequestTimer != nil {
            receiveActiveRequestTimer!.invalidate()
            receiveActiveRequestTimer = nil
        }
    }
    
    private func restartSearching() {
        stopSearching()
        startSearchingActiveRequests()
    }
    
    @objc func checkNewUserCodes() {
        checkNewUserCodesCounter += 1
        
        var userCodes = newUserCodes
        if activeRequestsArr.count > 0 {
            for request in activeRequestsArr {
                if !userCodes.contains(request.userCode) {
                    userCodes.append(request.userCode)
                }
            }
        }
        
        var isNeedToBecomeSender = false
        if checkNewUserCodesCounter == 5 {
            checkNewUserCodesCounter = 0
            if userCodes.count > 0 {
                isNeedToBecomeSender = true
            }
            
            restartSearching()
        } else if newUserCodes.count > 0 {
            isNeedToBecomeSender = true
        }
        
        if isNeedToBecomeSender {
            becomeSenderForUsersWithCodes(userCodes)
            newUserCodes.removeAll()
        }
    }
    
    func changeNameLabelVisibility(_ isHidden: Bool) {
        if isHidden {
            sendVC?.nameLabel.isHidden = true
            sendVC?.nameLabel.text = ""
            sendVC?.addressLabelTopConstraint.constant = 12
        } else {
            if isNameLabelShouldBeHidden() {
                sendVC?.nameLabel.isHidden = true
                sendVC?.nameLabel.text = ""
                sendVC?.addressLabelTopConstraint.constant = 12
            } else {
                let address = sendVC?.selectedRequestAddressLabel.text != nil ? sendVC!.selectedRequestAddressLabel.text! : ""
                sendVC?.nameLabel.text = DataManager.shared.name(for: address)
                sendVC?.nameLabel.isHidden = false
                sendVC?.addressLabelTopConstraint.constant = 20
            }
        }
    }
    
    func isNameLabelShouldBeHidden() -> Bool {
        guard let address = sendVC?.selectedRequestAddressLabel.text, address.isEmpty == false else {
            return true
        }
        
        return DataManager.shared.isAddressSaved(address) == false
    }
    
//
//    func randomRequestAddress() -> String {
//        var result = "0x"
//        result.append(randomString(length: 34))
//        return result
//    }
//
//    func randomString(length:Int) -> String {
//        let charSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
//        var c = charSet.characters.map { String($0) }
//        var s:String = ""
//        for _ in (1...length) {
//            s.append(c[Int(arc4random()) % c.count])
//        }
//        return s
//    }
//
//    func randomAmount() -> Double {
//        return Double(arc4random())/Double(UInt32.max)
//    }
//
//    func randomCurrencyID() -> NSNumber {
//        return NSNumber.init(value: 0)
//    }
//
//    func randomColor() -> UIColor {
//        return UIColor(red:   CGFloat(arc4random()) / CGFloat(UInt32.max),
//                       green: CGFloat(arc4random()) / CGFloat(UInt32.max),
//                       blue:  CGFloat(arc4random()) / CGFloat(UInt32.max),
//                       alpha: 1.0)
//    }
}

extension CreateTransactionDelegate {
    func createBTCTransaction() -> Bool {
        guard let requestIndex = selectedActiveRequestIndex, let walletIndex = selectedWalletIndex else {
            return false
        }
        
        let request = activeRequestsArr[requestIndex]
        let wallet = filteredWalletArray[walletIndex]
        //      let jwtToken = DataManager.shared.realmManager.account!.token
        let trData = DataManager.shared.coreLibManager.createTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                                         sendAddress: request.sendAddress,
                                                                         sendAmountString: request.sendAmount,
                                                                         feePerByteAmount: feeRate,
                                                                         isDonationExists: false,
                                                                         donationAmount: "0",
                                                                         isPayCommission: true,
                                                                         wallet: wallet,
                                                                         binaryData: &binaryData!,
                                                                         inputs: wallet.addresses)
        
        rawTransaction = trData.0
        rawTransactionEstimation = trData.1
        rawTransactionBigIntEstimation = BigInt(trData.2)
        
        return trData.1 >= 0
    }
    
    func createETHTransaction() -> Bool {
        guard let requestIndex = selectedActiveRequestIndex, let walletIndex = selectedWalletIndex else {
            return false
        }
        
        let request = activeRequestsArr[requestIndex]
        let wallet = filteredWalletArray[walletIndex]
        
        let sendAmount = request.sendAmount.stringWithDot.convertCryptoAmountStringToMinimalUnits(in: wallet.blockchainType.blockchain).stringValue
        
        let pointer: UnsafeMutablePointer<OpaquePointer?>?
        if !wallet.importedPrivateKey.isEmpty {
            let blockchainType = wallet.blockchainType
            let privatekey = wallet.importedPrivateKey
            let walletInfo = DataManager.shared.coreLibManager.createPublicInfo(blockchainType: blockchainType, privateKey: privatekey)
            switch walletInfo {
            case .success(let value):
                pointer = value["pointer"] as? UnsafeMutablePointer<OpaquePointer?>
            case .failure(let error):
                print(error)
                
                return false
            }
        } else {
            pointer = addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>
        }
        
        if wallet.isMultiSig {
            if self.linkedWallet == nil {
                rawTransaction = "Error"
                
                return false
            }
            
            let trData = DataManager.shared.createMultiSigTx(binaryData: &binaryData!,
                                                             wallet: self.linkedWallet!,
                                                             sendFromAddress: wallet.address,
                                                             sendAmountString: sendAmount,
                                                             sendToAddress: request.sendAddress,
                                                             msWalletBalance: wallet.availableAmount.stringValue,
                                                             gasPriceString: feeRate,
                                                             gasLimitString: submitEstimation)
            
            rawTransaction = trData.message
            
            return trData.isTransactionCorrect
        } else {
            let trData = DataManager.shared.coreLibManager.createEtherTransaction(addressPointer: pointer!,
                                                                                  sendAddress: request.sendAddress,
                                                                                  sendAmountString: sendAmount,
                                                                                  nonce: wallet.ethWallet!.nonce.intValue,
                                                                                  balanceAmount: wallet.ethWallet!.balance,
                                                                                  ethereumChainID: UInt32(wallet.blockchainType.net_type),
                                                                                  gasPrice: feeRate,
                                                                                  gasLimit: "40000")
            
            rawTransaction = trData.message
            
            return trData.isTransactionCorrect
        }
    }
}

extension SendPresenter: QrDataProtocol {
    func qrData(string: String, tag: String?) {
        let storyboard = UIStoryboard(name: "Send", bundle: nil)
        let sendStartVC = storyboard.instantiateViewController(withIdentifier: "sendStart") as! SendStartViewController
        sendStartVC.presenter.transactionDTO.update(from: string)
        
        sendVC!.navigationController?.pushViewController(sendStartVC, animated: true)
    }
}
