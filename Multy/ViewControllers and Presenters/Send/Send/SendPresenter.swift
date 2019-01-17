//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
//import MultyCoreLibrary

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
            
            sendVC?.updateUI()
        }
    }
    
    var walletsRequestsArr = [PaymentRequest]() {
        didSet {
            self.updateActiveRequests()
        }
    }
    
    var usersRequestsArr = [PaymentRequest]() {
        didSet {
            self.updateActiveRequests()
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
    
    
    func getFeeRate(_ blockchainType: BlockchainType, address: String?, completion: @escaping (_ feeRateDict: String, _ gasLimit: String?) -> ()) {
        DataManager.shared.getFeeRate(currencyID: blockchainType.blockchain.rawValue,
                                      networkID: UInt32(blockchainType.net_type),
                                      ethAddress: address,
                                      completion: { (dict, error) in
                                        print(dict)
                                        if let feeRates = dict!["speeds"] as? NSDictionary, let fastFeeRate = feeRates["Fast"] as? UInt64 {
                                            if let gasLimitForMS = dict!["gaslimit"] as? String {
                                                completion("\(fastFeeRate)", gasLimitForMS)
                                            } else {
                                                completion("\(fastFeeRate)", nil)
                                            }
                                        } else {
                                            //default values
                                            switch blockchainType.blockchain {
                                            case BLOCKCHAIN_BITCOIN:
                                                return completion("10", nil)
                                            case BLOCKCHAIN_ETHEREUM:
                                                return completion("1000000000", nil)
                                            default:
                                                return completion("1", nil)
                                            }
                                        }
        })
    }
    
    func filterArray() {
        var result = walletsArr.filter {
            ($0.isImported == false || $0.isImportedHasKey) && !$0.isMultiSig
        }
        
        
        if selectedActiveRequestIndex != nil  {
            let request = activeRequestsArr[selectedActiveRequestIndex!]
            
            if request.requester == .wallet {
                let blockchainType = BlockchainType.create(currencyID: UInt32(truncating: request.choosenAddress!.currencyID), netType: UInt32(truncating: request.choosenAddress!.networkID))
                let sendAmount = request.choosenAddress!.amountString.convertCryptoAmountStringToMinimalUnits(for: blockchainType.blockchain)
                //            let address = request.sendAddress
                
                result = result.filter {
                    $0.blockchainType == blockchainType && $0.availableAmount > sendAmount
                }
            } else {
                var requestBlockchainTypes : [BlockchainType] = []
                for address in request.supportedAddresses {
                    let blockchainType = BlockchainType.create(currencyID: UInt32(truncating: address.currencyID), netType: UInt32(truncating: address.networkID))
                    requestBlockchainTypes.append(blockchainType)
                }
                
                result = result.filter {
                    $0.availableAmount > BigInt.zero() && requestBlockchainTypes.contains($0.blockchainType)
                }
            }
        } else {
            result = result.filter {
                $0.availableAmount > BigInt.zero()
            }
        }
        
        //add token wallets
        filteredWalletArray = result // result.flatMap { $0.mainWalletWithTokenWallets } // for now
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveNewMultiReceiversRequests(notification:)), name: Notification.Name("newMultiReceiver"), object: nil)
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
        NotificationCenter.default.removeObserver(self, name: Notification.Name("newMultiReceiver"), object: nil)
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
        if isSendingAvailable && filteredWalletArray.count > selectedWalletIndex!  {
            let activeRequest = activeRequestsArr[selectedActiveRequestIndex!]
            transaction = TransactionDTO()
            if activeRequest.requester == .wallet {
                //FIXME:
                transaction!.sendAmountString = activeRequest.choosenAddress!.amountString
                transaction!.sendAddress = activeRequest.choosenAddress!.address
                transaction!.choosenWallet = filteredWalletArray[selectedWalletIndex!]
            } else {
                transaction = TransactionDTO()
                let selectedWallet = filteredWalletArray[selectedWalletIndex!]
                transaction!.choosenWallet = selectedWallet
                let walletBlockchainType = transaction!.assetsWallet.blockchainType
                if activeRequest.supportedAddresses.count > 0 {
                    for address in activeRequest.supportedAddresses {
                        let blockchain = Blockchain(rawValue: address.currencyID.uint32Value)
                        let requestAddressBlockchainType = BlockchainType.init(blockchain: blockchain, net_type: address.networkID.intValue)
                        if requestAddressBlockchainType == walletBlockchainType {
                            transaction!.sendAddress = address.address
                            break
                        }
                    }
                }
            }
        }
    }
    
    func goToEnterAmount() {
        if transaction != nil {
            let storyboard = UIStoryboard.init(name: "Send", bundle: nil)
            let sendAmountVC = storyboard.instantiateViewController(withIdentifier: "sendAmountVC") as! SendAmountViewController
            
            let assetsBlockchainType = transaction!.assetsWallet.blockchainType
            let blockchainType = transaction!.choosenWallet!.blockchainType
            sendVC?.enterAmountButton.isUserInteractionEnabled = false
            getFeeRate(assetsBlockchainType, address:transaction?.sendAddress) { [unowned self] (feeRate, gasLimit) in
                DispatchQueue.main.async {
                    self.transaction!.feeRate = BigInt(feeRate)
                    if blockchainType.blockchain == BLOCKCHAIN_ETHEREUM {
                        self.transaction!.ETHDTO!.gasLimit = gasLimit != nil ? BigInt(gasLimit!) : BigInt("21000")
                    } else if blockchainType.blockchain == BLOCKCHAIN_ERC20 {
                        self.transaction!.ETHDTO!.gasLimit = BigInt("\(plainERC20TxGasLimit)")
                    }
                    sendAmountVC.presenter.transactionDTO = self.transaction!
                    sendAmountVC.presenter.sendFromThisScreen = true
                    sendAmountVC.presenter.isPayForComissionCanBeChanged = false
                    var nc = self.sendVC?.navigationController
                    if nc == nil {
                        nc = self.sendVC?.presentingViewController?.navigationController
                    }
                    nc?.pushViewController(sendAmountVC, animated: true)
                    self.sendVC?.enterAmountButton.isUserInteractionEnabled = true
                }
            }
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
                    
                    let newAddress = wallet.shouldCreateNewAddressAfterTransaction ? self.addressData!["address"] as! String : ""
                    
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
        
        
        switch wallet.blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            completion(createBTCTransaction())
        case BLOCKCHAIN_ETHEREUM:
            createETHTransaction { completion($0) }
        case BLOCKCHAIN_ERC20:
            createERC20TokenTransaction { completion($0) }
        default:
            completion(false)
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
                self!.walletsRequestsArr = requests
                self!.sendVC?.updateUI()
            }
        }
    }
    
    @objc private func didReceiveNewMultiReceiversRequests(notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            let requests = notification.userInfo!["paymentRequests"] as! [PaymentRequest]
            
            if self != nil {
                self!.usersRequestsArr = requests
                self!.sendVC?.updateUI()
            }
        }
    }
    
    func updateActiveRequests() {
        let newRequests = walletsRequestsArr + usersRequestsArr
        var filteredRequestArray = newRequests.filter{ _ in true } //BigInt($0.sendAmount.convertCryptoAmountStringToMinimalUnits(in: BLOCKCHAIN_BITCOIN).stringValue) > Int64(0) }
        
        if selectedActiveRequestIndex != nil {
            // active request already exists
            let activeRequest = activeRequestsArr[selectedActiveRequestIndex!]
            let newActiveRequest = filteredRequestArray.filter{ $0.userID == activeRequest.userID}.first
            
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
        let trData = DataManager.shared.createTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                          sendAddress: request.choosenAddress!.address,
                                                          sendAmountString: request.choosenAddress!.amountString,
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
    
    
    
    func createETHTransaction(completion: @escaping(_ isTXCorrect: Bool) -> ()) {
        let requestIndex = selectedActiveRequestIndex
        let walletIndex = selectedWalletIndex
        
        if requestIndex == nil || walletIndex == nil {
            completion(false)
        }
        
        let request = activeRequestsArr[requestIndex!]
        let wallet = filteredWalletArray[walletIndex!]
        
        let sendAmount = request.choosenAddress!.amountString.stringWithDot.convertCryptoAmountStringToMinimalUnits(for: wallet.blockchainType.blockchain).stringValue
        
        if wallet.isMultiSig {
            if self.linkedWallet == nil {
                rawTransaction = "Error"
                
                completion(false)
            }
            
            let trData = DataManager.shared.createMultiSigTx(wallet: self.linkedWallet!,
                                                             sendFromAddress: wallet.address,
                                                             sendAmountString: sendAmount,
                                                             sendToAddress: request.choosenAddress!.address,
                                                             msWalletBalance: wallet.availableAmount.stringValue,
                                                             gasPriceString: feeRate,
                                                             gasLimitString: submitEstimation)
            
//            let trData = DataManager.shared.createMultiSigTx(binaryData: &binaryData!,
//                                                             wallet: self.linkedWallet!,
//                                                             sendFromAddress: wallet.address,
//                                                             sendAmountString: sendAmount,
//                                                             sendToAddress: request.sendAddress,
//                                                             msWalletBalance: wallet.availableAmount.stringValue,
//                                                             gasPriceString: feeRate,
//                                                             gasLimitString: submitEstimation)
            
            rawTransaction = trData.message
            
            completion(trData.isTransactionCorrect)
        } else {
            getFeeRate(wallet.blockchainType, address: request.choosenAddress!.address) { [unowned self] (fastGasPrice, gasLimit) in
                DispatchQueue.main.async {
                    let gasLimitEnd = gasLimit ?? "21000" //for non ms address
                    self.feeRate = fastGasPrice
                    
                    let trData = DataManager.shared.createETHTransaction(wallet: wallet,
                                                                         sendAmountString: sendAmount,
                                                                         destinationAddress: request.choosenAddress!.address,
                                                                         gasPriceAmountString: self.feeRate,
                                                                         gasLimitAmountString: gasLimitEnd)
                    
                    self.rawTransaction = trData.message
                    
                    completion(trData.isTransactionCorrect)
                }
            }
        }
    }
    
    func createERC20TokenTransaction(completion: @escaping(_ isTXCorrect: Bool) -> ()) {
//        transactionDTO.ETHDTO!.gasLimit = BigInt("\(plainERC20TxGasLimit)")
        let requestIndex = selectedActiveRequestIndex
        let walletIndex = selectedWalletIndex
        
        if requestIndex == nil || walletIndex == nil {
            completion(false)
        }
        
        let request = activeRequestsArr[requestIndex!]
        let wallet = filteredWalletArray[walletIndex!]
        
        let sendAmount = request.choosenAddress!.amountString.stringWithDot.convertCryptoAmountStringToMinimalUnits(for: wallet.tokenHolderWallet!.token).stringValue
        
        getFeeRate(wallet.blockchainType, address: request.choosenAddress!.address) { [unowned self] (fastGasPrice, gasLimit) in
            DispatchQueue.main.async {
                let gasLimitEnd = "\(plainERC20TxGasLimit)"
                self.feeRate = fastGasPrice
                
                let rawTX = DataManager.shared.createERC20TokenTransaction(wallet: self.transaction!.assetsWallet,
                                                                           tokenWallet: self.transaction!.choosenWallet!,
                                                                           sendTokenAmountString: sendAmount,
                                                                           destinationAddress: request.choosenAddress!.address,
                                                                           gasPriceAmountString: self.feeRate,
                                                                           gasLimitAmountString: gasLimitEnd)
                
                self.rawTransaction = rawTX.message
                
                completion(rawTX.isTransactionCorrect)
            }
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
