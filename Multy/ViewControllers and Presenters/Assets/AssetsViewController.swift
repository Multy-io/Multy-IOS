//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
import Alamofire
import CryptoSwift
import GSMessages
//import MultyCoreLibrary
//import BiometricAuthentication

private typealias ScrollViewDelegate = AssetsViewController
private typealias CollectionViewDelegate = AssetsViewController
private typealias CollectionViewDelegateFlowLayout = AssetsViewController
private typealias TableViewDelegate = AssetsViewController
private typealias TableViewDataSource = AssetsViewController
private typealias PresentingSheetDelegate = AssetsViewController
private typealias CancelDelegate = AssetsViewController
private typealias CreateWalletDelegate = AssetsViewController
private typealias LocalizeDelegate = AssetsViewController
private typealias PushTxDelegate = AssetsViewController
private typealias SendWalletsDelegate = AssetsViewController
private typealias BannersExtension = AssetsViewController

class AssetsViewController: UIViewController, QrDataProtocol, AnalyticsProtocol, BlockchainTransferProtocol, DeepLinksProtocol {
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewBottomConstraint: NSLayoutConstraint!
    weak var backupView: UIView?
    
    let presenter = AssetsPresenter()

//    let progressHUD = ProgressHUD(text: Constants.AssetsScreen.progressString)
    
    var isSeedBackupOnScreen = false
    
    var isFirstLaunch = true
    
    var isInsetCorrect = false
    
    var isInternetAvailable = true
    
    var loader = PreloaderView(frame: HUDFrame, text: "", image: #imageLiteral(resourceName: "walletHuge"))
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:
            #selector(handleRefresh(_:)),
                                 for: UIControlEvents.valueChanged)
        refreshControl.tintColor = #colorLiteral(red: 0, green: 0.5694742203, blue: 1, alpha: 1)
        refreshControl.transform  = CGAffineTransform(scaleX: 1.25, y: 1.25)
        
        return refreshControl
    }()
    
    var stringIdForInApp = ""
    var stringIdForInAppBig = ""
    
    var blockchainForTansfer: BlockchainType?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return currentStatusStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setpuUI()
        
        let dm = DataManager.shared
        let mkg = MasterKeyGenerator.shared
        self.performFirstEnterFlow { [unowned self, unowned dm, unowned mkg] (succeeded) in
            guard succeeded else {
                return
            }
            
            let isFirst = dm.checkIsFirstLaunch()
            if isFirst {
                self.sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: screenFirstLaunch)
                self.view.isUserInteractionEnabled = true
            } else {
                self.sendAnalyticsEvent(screenName: screenMain, eventName: screenMain)
            }
            
            let _ = mkg.generateMasterKey{_,_, _ in }
            
            self.checkOSForConstraints()
            
//            self.view.addSubview(self.progressHUD)
//            self.progressHUD.hide()
            if self.presenter.account != nil {
                self.tableView.frame.size.height = screenHeight - self.tabBarController!.tabBar.frame.height
            }
            dm.socketManager.start()
            dm.subscribeToFirebaseMessaging() 
            
            //FIXME: add later or refactor
            
            self.successLaunch()
            
            self.openTxFromPush()
        }
    }
    
    func setpuUI() {
    //    GSMessage.font = UIFont(name: "AvenirNext-Medium", size: 15.0)!
        presenter.assetsVC = self
        checkOSForConstraints()
        backUpView()
        setupStatusBar()
        registerCells()
        tableView.accessibilityIdentifier = "AssetsTableView"
        tableView.addSubview(self.refreshControl)
        view.isUserInteractionEnabled = false
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.addSubview(loader)
    }
    
    func performFirstEnterFlow(completion: @escaping(_ isUpToDate: Bool) -> ()) {
        switch isDeviceJailbroken() {
        case true:
            self.presenter.isJailed = true
            completion(false)
        case false:
            self.presenter.isJailed = false
            loader.show(customTitle: localize(string: Constants.checkingVersionString))

            if !(ConnectionCheck.isConnectedToNetwork()) {
                self.isInternetAvailable = false
                loader.hide()
                completion(true)
                return
            }
            DataManager.shared.getServerConfig { [unowned self] (hardVersion, softVersion, err) in
                self.loader.hide()
                
                if hardVersion == nil || softVersion == nil {
//                    self.presentUpdateAlert(idOfAlert: 2)
                    completion(true)
                    return
                }
                
                let dictionary = Bundle.main.infoDictionary!
                let buildVersion = (dictionary["CFBundleVersion"] as! NSString).integerValue
                
                if buildVersion < hardVersion! {
                    self.presentUpdateAlert(idOfAlert: 0)
                    completion(false)
                } else if buildVersion < softVersion! {
                    self.presenter.presentSoftUpdate(completion: completion)
                    completion(true)
                } else if softVersion! > hardVersion! && softVersion! > buildVersion {
                    self.presenter.presentSoftUpdate(completion: completion)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    func successLaunch() {
        let _ = UserPreferences.shared
        AppDelegate().saveMkVersion()
        if !self.presentTermsOfService() {
            self.presenter.updateWalletsInfo(isInternetAvailable: self.isInternetAvailable)
        }
    }
    
//    func autorizeFromAppdelegate() {
//        DataManager.shared.realmManager.getAccount { (acc, err) in
//            DataManager.shared.realmManager.fetchCurrencyExchange { (currencyExchange) in
//                if currencyExchange != nil {
//                    DataManager.shared.currencyExchange.update(currencyExchangeRLM: currencyExchange!)
//                }
//            }
//            isNeedToAutorise = acc != nil
//            DataManager.shared.apiManager.userID = acc == nil ? "" : acc!.userID
//            //MAKR: Check here isPin option from NSUserDefaults
//            UserPreferences.shared.getAndDecryptPin(completion: { [weak self] (code, err) in
//                if code != nil && code != "" {
//                    isNeedToAutorise = true
//                    let appDel = UIApplication.shared.delegate as! AppDelegate
//                    appDel.authorization(isNeedToPresentBiometric: true)
//                }
//            })
//        }
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        if self.presenter.isJailed {
            self.presentUpdateAlert(idOfAlert: 0)
//            self.presentWarningAlert(message: localize(string: Constants.jailbrokenDeviceWarningString))
        }
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: presenter.account == nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msMembersUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msWalletDeleted"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msTransactionUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("msWalletUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("exchageUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("transactionUpdated"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("walletDeleted"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("resyncCompleted"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(bluetoothReachabilityChangedNotificationName), object: nil)
        NotificationCenter.default.removeObserver(self, name: Notification.Name(socketManagerStatusChangedNotificationName), object: nil)
        
        presenter.changeReceivingEnabling(false)
        
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleExchangeUpdatedNotifiction(notification:)), name: NSNotification.Name("exchageUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleTransactionUpdatedNotification(notification :)), name: NSNotification.Name("transactionUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMembersUpdatedNotification(notification:)), name: NSNotification.Name("msMembersUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleWalletDeletedNotification(notification:)), name: NSNotification.Name("msWalletDeleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleMsTransactionUpdatedNotification(notification:)), name: NSNotification.Name("msTransactionUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleWalletUpdatedNotification(notification:)), name: NSNotification.Name("msWalletUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleResyncCompleteNotification(notification:)), name: NSNotification.Name("resyncCompleted"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateUI), name: NSNotification.Name.UIApplicationWillEnterForeground, object:nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive(notification:)), name: Notification.Name.UIApplicationDidBecomeActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangedBluetoothReachability(notification:)), name: Notification.Name(bluetoothReachabilityChangedNotificationName), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChangedSocketManagerStatus(notification:)), name: NSNotification.Name(socketManagerStatusChangedNotificationName), object: nil)
        super.viewWillAppear(animated)
        
        if !self.isFirstLaunch || !self.isInternetAvailable {
            self.presenter.updateWalletsInfo(isInternetAvailable: isInternetAvailable)
        }
        
        self.isFirstLaunch = false
        presenter.isBluetoothReachable = BLEManager.shared.reachability == .reachable
        presenter.changeReceivingEnabling(true)
        
        self.updateUI()
        
        if presenter.account == nil {
            view.isUserInteractionEnabled = false
            
            DataManager.shared.isAccountExists { [unowned self] in
                if !$0 {
                    DispatchQueue.main.async { [unowned self] in
                        let _ = self.presentTermsOfService()
                        self.view.isUserInteractionEnabled = true
                    }
                } else {
                    self.view.isUserInteractionEnabled = true
                }
            }
        }
        
        refreshControl.beginRefreshing()
        refreshControl.endRefreshing()
    }
    
    @objc fileprivate func handleWalletDeletedNotification(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateWalletsInfo(isInternetAvailable: self.isInternetAvailable)
        }
    }
    
    @objc fileprivate func handleMembersUpdatedNotification(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateWalletsInfo(isInternetAvailable: self.isInternetAvailable)
        }
    }
    
    @objc fileprivate func handleMsTransactionUpdatedNotification(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateWalletsInfo(isInternetAvailable: self.isInternetAvailable)
            
            let tx = notification.userInfo?["transaction"] as? NSDictionary
            
            if tx != nil {
                guard let txStatus = tx!["type"] as? Int,
                    txStatus == SocketMessageType.multisigTxPaymentRequest.rawValue else {
                        return
                }

                
                let message = NSMutableAttributedString()
                message.append(NSAttributedString(string:self.localize(string: Constants.youReceivedMultisigRequestString), attributes: [.font: UIFont(name: "AvenirNext-Medium", size: 15)!]))
                
                GSMessage.successBackgroundColor = #colorLiteral(red: 0.08235294118, green: 0.4941176471, blue: 0.9843137255, alpha: 0.96)
                self.showMessage(message, type: .success, options: [.height(64.0)])
            }
        }
    }
    
    @objc fileprivate func handleMsTransactionDeclinedNotification(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateWalletsInfo(isInternetAvailable: self.isInternetAvailable)
        }
    }
    
    @objc fileprivate func handleWalletUpdatedNotification(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateWalletsInfo(isInternetAvailable: self.isInternetAvailable)
        }
    }
    
    @objc fileprivate func handleExchangeUpdatedNotifiction(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateExchange()
        }
    }
    
    @objc fileprivate func handleTransactionUpdatedNotification(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateWalletAfterSockets()
           
            let userInfo = notification.userInfo
            if userInfo != nil {
                let notifictionMsg = userInfo!["NotificationMsg"] as! NSDictionary
                guard let txStatus = notifictionMsg["transactionType"] as? Int,
                    let addressTo = notifictionMsg["to"] as? String else {
                        return
                }
                
                guard let amount = notifictionMsg["amount"] as? String,
                    let currencyID = notifictionMsg["currencyid"] as? UInt32,
                    let networkID = notifictionMsg["networkid"] as? UInt32 else {
                        return
                }
                let blockchainType = BlockchainType.create(currencyID: currencyID, netType: networkID)
                let cryptoValueString = BigInt(amount).cryptoValueString(for: blockchainType.blockchain)
                
                let amountString = cryptoValueString + " " + blockchainType.shortName
                if txStatus == TxStatus.MempoolIncoming.rawValue {
                    let message = NSMutableAttributedString()
                    message.append(NSAttributedString(string:self.localize(string: Constants.youReceivedString), attributes: [.font: UIFont(name: "AvenirNext-Medium", size: 15)!]))
                    message.append(NSAttributedString(string: " \(amountString) ", attributes: [.font: UIFont(name: "AvenirNext-Bold", size: 15)!]))
                    let wallet = self.presenter.wallets!.filter {$0.address == addressTo}.first
                    
                    GSMessage.successBackgroundColor = #colorLiteral(red: 0.168627451, green: 0.662745098, blue: 0.3764705882, alpha: 0.96)
                    self.showMessage(message, type: .success, options: [.height(64.0), .handleTap({ [unowned self] in
                        self.goToWalletVC(wallet)
                    })])
                }
            }
        }
    }
    
    @objc fileprivate func handleResyncCompleteNotification(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateWalletsInfo(isInternetAvailable: self.isInternetAvailable)
        }
    }
    
    @objc private func didChangedBluetoothReachability(notification: Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateBluetoothReachability()
        }
    }
    
    @objc private func didChangedSocketManagerStatus(notification: Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateSocketManagerStatus()
        }
    }
    
    @objc private func applicationDidBecomeActive(notification: Notification) {
        DispatchQueue.main.async { [unowned self] in
            self.presenter.updateBluetoothReachability()
        }
    }
    
    override func viewDidLayoutSubviews() {
        tabBarController?.tabBar.frame = presenter.tabBarFrame
        tableView.frame.size.height = screenHeight - presenter.tabBarFrame.height
    }
    
    func handleExchangeUpdate() {
        for cell in self.tableView.visibleCells {
            if cell.isKind(of: WalletTableViewCell.self) {
                (cell as! WalletTableViewCell).fillInCell()
            }
        }
    }
    
    func handleUpdateWalletAfterSockets() {
        self.tableView.reloadData()
    }
    
    func backUpView() {
        if backupView != nil {
            return
        }
        
        let view = UIView()
        if screenHeight == heightOfX || screenHeight == heightOfXSMax {
            view.frame = CGRect(x: 16, y: 50, width: screenWidth - 32, height: Constants.AssetsScreen.backupButtonHeight)
        } else {
            view.frame = CGRect(x: 16, y: 25, width: screenWidth - 32, height: Constants.AssetsScreen.backupButtonHeight)
        }
        
        view.layer.cornerRadius = 20
        view.backgroundColor = #colorLiteral(red: 0.9229970574, green: 0.08180250973, blue: 0.2317947149, alpha: 1)
        view.layer.shadowColor = #colorLiteral(red: 0.4156862745, green: 0.1490196078, blue: 0.168627451, alpha: 0.6)
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = .zero
        view.layer.shadowRadius = 10
        view.isHidden = false
        let image = UIImageView()
        image.image = #imageLiteral(resourceName: "warninngBigWhite")
        image.frame = CGRect(x: 13, y: 11, width: 22, height: 22)
        
        let chevronImg = UIImageView(frame: CGRect(x: view.frame.width - 24, y: 15, width: 13, height: 13))
        chevronImg.image = #imageLiteral(resourceName: "chevron__")
        let btn = UIButton()
        btn.frame = CGRect(x: 50, y: 0, width: chevronImg.frame.origin.x - 50, height: view.frame.height)
        if screenHeight <= heightOfFive {
            btn.frame = CGRect(x: 50, y: -3, width: chevronImg.frame.origin.x - 50, height: view.frame.height)
        }
        btn.setTitle(localize(string: Constants.backupNeededString), for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.minimumScaleFactor = 0.5
        btn.contentHorizontalAlignment = .left
        btn.addTarget(self, action: #selector(goToSeed), for: .touchUpInside)
        
        view.addSubview(btn)
        view.addSubview(image)
        view.addSubview(chevronImg)
        backupView = view
        self.view.addSubview(backupView!)
        view.isHidden = true
        view.isUserInteractionEnabled = false
    }
    
    func updateReceiverUI() {
        guard let bannerCell = self.tableView.cellForRow(at: [0,0]) as? BannerTableViewCell else { return }
        bannerCell.collectionView!.reloadData()
    }
    
    func setupStatusBar() {
        if screenHeight == heightOfX || screenHeight == heightOfXSMax {
            statusView.frame.size.height = 44
        }
        let colorTop = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8).cgColor
        let colorBottom = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.0).cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorTop, colorBottom]
        gradientLayer.locations = [0.6, 1.0]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: statusView.frame.height)
        statusView.layer.addSublayer(gradientLayer)
    }
    
    @objc func goToSeed() {
        sendAnalyticsEvent(screenName: screenMain, eventName: backupSeedTap)
        let stroryboard = UIStoryboard(name: "SeedPhrase", bundle: nil)
        let vc = stroryboard.instantiateViewController(withIdentifier: "seedAbout")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc fileprivate func handleWalletDeletedNotification() {
         self.presenter.updateWalletsInfo(isInternetAvailable: isInternetAvailable)
    }
    
    @objc fileprivate func updateWallets() {
        self.presenter.updateWalletsInfo(isInternetAvailable: isInternetAvailable)
    }
    
    //MARK: Setup functions
    
    func checkOSForConstraints() {
        if #available(iOS 11.0, *) {
            //OK: Storyboard was made for iOS 11
        } else {
            self.tableViewTopConstraint.constant = 0
        }
    }
    
    func registerCells() {
        let walletCell = UINib.init(nibName: "WalletTableViewCell", bundle: nil)
        self.tableView.register(walletCell, forCellReuseIdentifier: "walletCell")
        
        let bannerCell = UINib.init(nibName: "BannerTableViewCell", bundle: nil)
        self.tableView.register(bannerCell, forCellReuseIdentifier: "bannerCellReuseID")
        
        let newWalletCell = UINib.init(nibName: "NewWalletTableViewCell", bundle: nil)
        self.tableView.register(newWalletCell, forCellReuseIdentifier: "newWalletCell")
        
        let textCell = UINib.init(nibName: "TextTableViewCell", bundle: nil)
        self.tableView.register(textCell, forCellReuseIdentifier: "textCell")
        
        let logoCell = UINib.init(nibName: "LogoTableViewCell", bundle: nil)
        self.tableView.register(logoCell, forCellReuseIdentifier: "logoCell")
        
        let createOrRestoreCell = UINib.init(nibName: "CreateOrRestoreBtnTableViewCell", bundle: nil)
        self.tableView.register(createOrRestoreCell, forCellReuseIdentifier: "createOrRestoreCell")
    }
    
    func goToWalletVC(indexPath: IndexPath) {
//        let walletVC = presenter.getWalletViewController(indexPath: indexPath)
        let wallet = presenter.wallets?[indexPath.row - 2]
        goToWalletVC(wallet)
    }
    
    func goToWalletVC(_ wallet: UserWalletRLM?) {
        if !wallet!.isSyncing.boolValue {
            var vc : UIViewController?
            if wallet!.multisigWallet != nil && wallet!.multisigWallet?.deployStatus.intValue != DeployStatus.deployed.rawValue {
                let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
                if wallet!.multisigWallet?.deployStatus.intValue == DeployStatus.pending.rawValue {
                    presentAlert(withTitle: localize(string: Constants.warningString),
                                 andMessage: localize(string: Constants.pendingMultisigAlertString))
                    
                    return
                }
                vc  = storyboard.instantiateViewController(withIdentifier: "waitingMembers") as! WaitingMembersViewController
                (vc as! WaitingMembersViewController).presenter.wallet = wallet!
                (vc as! WaitingMembersViewController).presenter.account = presenter.account
            } else {
                let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
                vc = storyboard.instantiateViewController(withIdentifier: "newWallet") as! WalletViewController
                (vc as! WalletViewController).presenter.account = presenter.account
                (vc as! WalletViewController).presenter.wallet = wallet
            }
            
            if vc != nil {
                self.navigationController?.pushViewController(vc!, animated: true)
            }
        } else {
            presentAlert(withTitle: localize(string: Constants.warningString),
                         andMessage: localize(string: Constants.syncingAlertString))
        }
    }
    
    @objc func updateUI() {
        tabBarController?.tabBar.frame = presenter.tabBarFrame
//        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: presenter.account == nil)
        tableView.frame.size.height = screenHeight - presenter.tabBarFrame.height
        self.tableView.reloadData()
    }
    
    func presentUpdateAlert(idOfAlert: Int) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let slpashScreen = storyboard.instantiateViewController(withIdentifier: "splash") as! SplashViewController
        slpashScreen.isJailAlert = idOfAlert
        slpashScreen.parentVC = self
        slpashScreen.modalPresentationStyle = .overCurrentContext
        self.present(slpashScreen, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Storyboard.createWalletVCSegueID {
            let createVC = segue.destination as! CreateWalletViewController
            createVC.presenter.account = presenter.account
        }
    }
    
    func presentTermsOfService() -> Bool {
        let result = DataManager.shared.checkTermsOfService()
        if !result {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let termsVC = storyBoard.instantiateViewController(withIdentifier: "termsVC") as! TermsOfServiceViewController
            termsVC.sendDeepLinksDelegate = self
            self.present(termsVC, animated: true, completion: nil)
        }
        return !result
    }
    
    func isOnWindow() -> Bool {
        return self.navigationController!.topViewController!.isKind(of: AssetsViewController.self) && isVisible()
    }
    
    //    FORCE TOUCH EVENTS
    // qr
    func openQR() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.presenter.account != nil {
                let storyboard = UIStoryboard(name: "Send", bundle: nil)
                let qrScanVC = storyboard.instantiateViewController(withIdentifier: "qrScanVC") as! QrScannerViewController
                qrScanVC.qrDelegate = self
                qrScanVC.presenter.isFast = true
                self.present(qrScanVC, animated: true, completion: nil)
            }
        }
    }
    
    func qrData(string: String, tag: String?) {
        if tag == "joinMS" {
            let storyboard = UIStoryboard(name: "Receive", bundle: nil)
            let chooseWalletVC = storyboard.instantiateViewController(withIdentifier: "ReceiveStart") as! ReceiveStartViewController
            chooseWalletVC.presenter.multisigFunc(inviteCode: string)
            chooseWalletVC.presenter.displayedBlockchainOnly = blockchainForTansfer
            chooseWalletVC.presenter.isNeedToPop = true
            chooseWalletVC.whereFrom = self
            navigationController?.pushViewController(chooseWalletVC, animated: true)
        } else {
            let storyboard = UIStoryboard(name: "Send", bundle: nil)
            let destVC = storyboard.instantiateViewController(withIdentifier: "sendStart") as! SendStartViewController
            destVC.presenter.transactionDTO.update(from: string)
            navigationController?.pushViewController(destVC, animated: true)
        }
    }
    // -------------
    
    // send to
    func sendTransactionTo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.presenter.account != nil {
                let storyboard = UIStoryboard(name: "Send", bundle: nil)
                let destVC = storyboard.instantiateViewController(withIdentifier: "sendStart") as! SendStartViewController
                self.navigationController?.pushViewController(destVC, animated: true)
            }
        }
    }
    // -------------
    
    // receive
    func openReceive() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.presenter.account != nil {
                let storyboard = UIStoryboard(name: "Receive", bundle: nil)
                let receiveVC = storyboard.instantiateViewController(withIdentifier: "ReceiveStart")
                self.navigationController?.pushViewController(receiveVC, animated: true)
            }
        }
    }
    // -------------
    
    
    func setBlockchain(blockchain: BlockchainType) {
        blockchainForTansfer = blockchain
    }
    
    func sendDeepLinksParams(params: DragonDLObj) {
        loader.show(customTitle: "Creating")
        let isNeedEthTest: Bool = params.chaintType == 4 ? true : false
        createFirstWallets(isNeedEthTest: isNeedEthTest) { (error) in
            if error == nil {
                self.loader.hide()
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.openBrowserWith(params: params)
            }
        }
    }
    
    func sendDL(params: NSDictionary) {
        presenter.magicReceiveParams = params
        createFirstWallets(isNeedEthTest: false) { (error) in
            
        }
    }
}

extension CreateWalletDelegate: CreateWalletProtocol {
    func goToCreateWallet(tag: String) {
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        if tag == "createNewWallet" {
            performSegue(withIdentifier: Constants.Storyboard.createWalletVCSegueID, sender: Any.self)
        } else if tag == "newEthMultiSig" {
            let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
            let createMSVC = storyboard.instantiateViewController(withIdentifier: "creatingMultiSigVC")
            navigationController?.pushViewController(createMSVC, animated: true)
        } else if tag == "joinToMultiSig" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let joinVC = storyboard.instantiateViewController(withIdentifier: "joinMultiSig") as! JoinMultiSigViewController
            joinVC.qrDelegate = self
            joinVC.blockchainTransferDelegate = self
            navigationController?.pushViewController(joinVC, animated: true)
        } else if tag == "importWallet" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let importMS = storyboard.instantiateViewController(withIdentifier: "importMS") as! ImportMSViewController
            importMS.presenter.account = presenter.account
            importMS.presenter.isForMS = false
            importMS.sendWalletsDelegate = self
            navigationController?.pushViewController(importMS, animated: true)
        } else if tag == "importMS" {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let importMS = storyboard.instantiateViewController(withIdentifier: "importMS") as! ImportMSViewController
            importMS.presenter.account = presenter.account
            importMS.presenter.isForMS = true
            importMS.sendWalletsDelegate = self
            navigationController?.pushViewController(importMS, animated: true)
        }
    }
}

extension CancelDelegate: CancelProtocol {
    func cancelAction() {
//        presentDonationVCorAlert()
        self.makePurchaseFor(productId: self.stringIdForInApp)
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: presenter.account == nil)
    }
    
    func donate50(idOfProduct: String) {
        self.makePurchaseFor(productId: idOfProduct)
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: presenter.account == nil)
    }
    
    func presentNoInternet() {
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: presenter.account == nil)
    }
}

extension PresentingSheetDelegate: OpenCreatingSheet {
    //MARK: CreateNewWalletProtocol
    func openNewWalletSheet() {
        if self.presenter.account == nil {
            return
        }
        
//        let transition = CATransition()
//        transition.duration = 0.4
//        transition.type = kCATransitionReveal
//        transition.subtype = kCATransitionFromTop
//        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
//        view.window!.layer.add(transition, forKey: kCATransition)
        
        
        
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        sendAnalyticsEvent(screenName: screenMain, eventName: createWalletTap)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let creatingVC = storyboard.instantiateViewController(withIdentifier: "creatingVC") as! CreatingWalletActionsViewController
        creatingVC.cancelDelegate = self
        creatingVC.createProtocol = self
        creatingVC.modalPresentationStyle = .custom
        creatingVC.modalTransitionStyle = .crossDissolve
        self.present(creatingVC, animated: true, completion: nil)
        self.stringIdForInApp = "io.multy.importWallet5"
        
        
//        let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
//        let creatingVC = storyboard.instantiateViewController(withIdentifier: "creatingMultiSigVC") as! CreateMultiSigViewController
//
//        navigationController?.pushViewController(creatingVC, animated: true)
    }
}

extension TableViewDelegate : UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.tappedIndexPath = indexPath
        
        switch indexPath {
        case [0,0]:
            sendAnalyticsEvent(screenName: screenMain, eventName: logoTap)
            break
        case [0,1]:
            break
        case [0,2]:
            if self.presenter.account == nil {
                if isServerConnectionExist == false {
                    checkServerConnection()
                } else {
                    sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: createFirstWalletTap)
                    //                self.performSegue(withIdentifier: "createWalletVC", sender: Any.self)
                    self.view.isUserInteractionEnabled = false
                    createFirstWallets(isNeedEthTest: false) { [unowned self] (error) in
                        self.view.isUserInteractionEnabled = true
                        
                        if error == nil {
                            print("Wallets created")
                        }
                    }
                }
            } else {
                if self.presenter.isWalletExist() {
                    goToWalletVC(indexPath: indexPath)
                } else {
                    break
                }
            }
        case [0,3]:
            if self.presenter.account == nil {
                if isServerConnectionExist == false {
                    checkServerConnection()
                    return
                }
                sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: restoreMultyTap)
                let storyboard = UIStoryboard(name: "SeedPhrase", bundle: nil)
                let backupSeedVC = storyboard.instantiateViewController(withIdentifier: "backupSeed") as! CheckWordsViewController
                backupSeedVC.isRestore = true
                backupSeedVC.presenter.accountType = .multy
                
                self.navigationController?.pushViewController(backupSeedVC, animated: true)
            } else {
                if self.presenter.isWalletExist() {
                    goToWalletVC(indexPath: indexPath)
                }
            }
        case [0,4]:
            if self.presenter.account == nil {
                if isServerConnectionExist == false {
                    checkServerConnection()
                    return
                }
                sendAnalyticsEvent(screenName: screenMain, eventName: importMetamaskTap)
                let importMetaMaskVC = viewControllerFrom("SeedPhrase", "ImportMetaMask") as! ImportMetaMaskInfoViewController
                self.navigationController?.pushViewController(importMetaMaskVC, animated: true)
//                sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: restoreMultyTap)
//                let storyboard = UIStoryboard(name: "SeedPhrase", bundle: nil)
//                let backupSeedVC = storyboard.instantiateViewController(withIdentifier: "backupSeed") as! CheckWordsViewController
//                backupSeedVC.isRestore = true
//                self.navigationController?.pushViewController(backupSeedVC, animated: true)
            } else {
                if self.presenter.isWalletExist() {
                    goToWalletVC(indexPath: indexPath)
                }
            }
        default:
            if self.presenter.isWalletExist() {
                goToWalletVC(indexPath: indexPath)
            }
        }
    }
    

    func checkServerConnection() {
        loader.show(customTitle: "Connecting")
        DataManager.shared.getServerConfig { (hard, soft, err) in
            self.loader.hide()
            if err != nil {
                self.presentAlert(withTitle: self.localize(string: Constants.serverOffTitle), andMessage: self.localize(string: Constants.serverOffMessage))
            }
        }
    }
    
   

    func createFirstWallets(isNeedEthTest: Bool, completion: @escaping(_ error: String?) -> ()) {
        self.presenter.makeAuth { [unowned self] (answer) in
            self.presenter.createFirstWallets(walletName: nil, blockchianType: BlockchainType.create(currencyID: 0, netType: 0), completion: { [unowned self] (answer, err) in
                self.presenter.createFirstWallets(walletName: nil, blockchianType: BlockchainType.create(currencyID: 60, netType: 1), completion: { [unowned self] (answer, err) in
                    if isNeedEthTest {
                        self.presenter.createFirstWallets(walletName: nil, blockchianType: BlockchainType.create(currencyID: 60, netType: 4), completion: { [unowned self] (answer, err) in
                            //FIXME: possibly unused request
                            self.presenter.getWalletsVerbose(completion: { (complete) in
                                if self.presenter.magicReceiveParams != nil {
                                    self.presenter.openMagicReceiveWith(params: self.presenter.magicReceiveParams!)
                                }
                                completion(nil)
                            })
                        })
                    } else {
                        self.presenter.getWalletsVerbose(completion: { (complete) in
                            if self.presenter.magicReceiveParams != nil {
                                self.presenter.openMagicReceiveWith(params: self.presenter.magicReceiveParams!)
                            }
                            completion(nil)
                        })
                    }
                })
            })
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case [0,0]:         // PORTFOLIO CELL  or LOGO
            if presenter.account == nil {
                return 220
            } else {
                if presenter.account!.isSeedPhraseSaved() {
//                    return 340
//                    return screenHeight == heightOfFive ? 270 : 320
                    return screenHeight == heightOfFive ? 270 : 320
                } else {
//                    return 340 + Constants.AssetsScreen.backupAssetsOffset
                    let heightConstant: CGFloat = screenHeight == heightOfFive ? 295 : 320
                    return heightConstant + Constants.AssetsScreen.backupAssetsOffset
                }
            }
        case [0,1]:        // !!!NEW!!! WALLET CELL
            if presenter.account == nil {
                return 10
            }
            return 75
        case [0,2]:
            if self.presenter.account != nil {
                if presenter.isWalletExist() {
                    return 104
                } else {
                    return 121
                }
            } else {   // acc == nil
                return 100
            }
        case [0,3]:
            if self.presenter.account != nil {
                return 104
            } else {
                return 100
            }
        default:
            return 104
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case [0,0]:         // PORTFOLIO CELL  or LOGO
            if presenter.account == nil {
                return 220
            } else {
                if presenter.account!.isSeedPhraseSaved() {
                    //                    return 340
                    //                    return screenHeight == heightOfFive ? 270 : 320
                    return screenHeight == heightOfFive ? 270 : 340
                } else {
                    //                    return 340 + Constants.AssetsScreen.backupAssetsOffset
                    let heightConstant: CGFloat = screenHeight == heightOfFive ? 295 : 340
                    return heightConstant + Constants.AssetsScreen.backupAssetsOffset
                }
            }
        case [0,1]:        // !!!NEW!!! WALLET CELL
            if presenter.account == nil {
                return 10
            }
            return 75
        case [0,2]:
            if self.presenter.account != nil {
                if presenter.isWalletExist() {
                    return 104
                } else {
                    return 121
                }
            } else {   // acc == nil
                return 100
            }
        case [0,3]:
            if self.presenter.account != nil {
                return 104
            } else {
                return 100
            }
        default:
            return 104
        }
    }
    
    override var preferredContentSize: CGSize {
        get {
            self.tableView.layoutIfNeeded()
            return self.tableView.contentSize
        }
        set { }
    }
}

extension TableViewDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.presenter.account != nil {
            if presenter.isWalletExist() {
                return 2 + presenter.wallets!.count  // logo / new wallet /wallets
            } else {
                return 3                                     // logo / new wallet / text cell
            }
        } else {
            return 5                                         // logo / empty cell / create wallet / restore / restore metamask
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case [0,0]:         // PORTFOLIO CELL  or LOGO
            if presenter.account == nil {
                let logoCell = self.tableView.dequeueReusableCell(withIdentifier: "logoCell") as! LogoTableViewCell
                return logoCell
            } else {
//                let portfolioCell = self.tableView.dequeueReusableCell(withIdentifier: "portfolioCell") as! PortfolioTableViewCell
//                portfolioCell.mainVC = self
//                portfolioCell.delegate = self
//                print(presenter.countFiatMoney())

                let bannerCell = self.tableView.dequeueReusableCell(withIdentifier: "bannerCellReuseID") as! BannerTableViewCell
                bannerCell.mainVC = self
                bannerCell.delegate = self
                bannerCell.dataSource = self
                
                return bannerCell
            }
        case [0,1]:        // !!!NEW!!! WALLET CELL
            let newWalletCell = self.tableView.dequeueReusableCell(withIdentifier: "newWalletCell") as! NewWalletTableViewCell
            newWalletCell.delegate = self
            
            if presenter.account == nil {
                newWalletCell.hideAll(flag: true)
            } else {
                newWalletCell.hideAll(flag: false)
            }
            return newWalletCell
        case [0,2]:
            if self.presenter.account != nil {
                //MARK: change logiv
                
                if presenter.isWalletExist() {
                    let walletCell = self.tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
                    //                    walletCell.makeshadow()
                    walletCell.wallet = presenter.wallets?[indexPath.row - 2]
                    walletCell.accessibilityIdentifier = "\(indexPath.row - 2)"
                    walletCell.fillInCell()
                    
                    return walletCell
                } else {
                    let textCell = self.tableView.dequeueReusableCell(withIdentifier: "textCell") as! TextTableViewCell
                    
                    return textCell
                }
            } else {   // acc == nil
                let createCell = self.tableView.dequeueReusableCell(withIdentifier: "createOrRestoreCell") as! CreateOrRestoreBtnTableViewCell
                createCell.makeCreateCell()
                return createCell
            }
        case [0,3]:
            if self.presenter.account != nil {
                let walletCell = self.tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
                //                walletCell.makeshadow()
                walletCell.wallet = presenter.wallets?[indexPath.row - 2]
                walletCell.accessibilityIdentifier = "\(indexPath.row - 2)"
                walletCell.fillInCell()
                
                return walletCell
            } else {
                let restoreCell = self.tableView.dequeueReusableCell(withIdentifier: "createOrRestoreCell") as! CreateOrRestoreBtnTableViewCell
                restoreCell.makeRestoreCell()
                
                return restoreCell
            }
        case [0,4]:
            if self.presenter.account != nil {
                let walletCell = self.tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
                //                walletCell.makeshadow()
                walletCell.wallet = presenter.wallets?[indexPath.row - 2]
                walletCell.accessibilityIdentifier = "\(indexPath.row - 2)"
                walletCell.fillInCell()
                
                return walletCell
            } else {
                let importMetamaskCell = self.tableView.dequeueReusableCell(withIdentifier: "createOrRestoreCell") as! CreateOrRestoreBtnTableViewCell
                importMetamaskCell.makeMetaMaskCell()
                
                return importMetamaskCell
            }
        default:
            let walletCell = self.tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
            
            walletCell.wallet = presenter.wallets?[indexPath.row - 2]
            walletCell.accessibilityIdentifier = "\(indexPath.row - 2)"
            walletCell.fillInCell()
            
            return walletCell
        }
    }
    
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.presenter.updateWalletsInfo(isInternetAvailable: isInternetAvailable)
//        presenter.updateWalletsInfoByRefresh(isInternetAvailable: isInternetAvailable) { (isEnd) in
//            self.presenter.unlockUI(isNeedToScroll: true)
//        }
    }
    
    func blockCollection(block: Bool, isNeedToScroll: Bool) {
        tableView.cellForRow(at: [0,0])?.isUserInteractionEnabled = !block
        if isNeedToScroll == true {
            tableView.scrollToTop()
        }
//        self.view.isUserInteractionEnabled = !block
    }
    
}

extension CollectionViewDelegateFlowLayout : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 277  //widthOfNormal
        if screenWidth == widthOfSmall {
            height = 250.0
        } else if screenWidth == widthOfBig {
            height = 297.0
        }
//        return CGSize(width: screenWidth, height: 277 /* (screenWidth / 375.0)*/)
        return CGSize(width: screenWidth, height: height /* (screenWidth / 375.0)*/)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension PushTxDelegate {
    func openTxFromPush() {
        let app = UIApplication.shared.delegate as? AppDelegate
        
        if app?.info != nil {
//            presentAlert(with: app?.info.debugDescription)
            openTx(app!.info!)
//            app?.info = nil
        }
    }
    
    func openTx(_ info: [AnyHashable: Any]) {
        if let txID = info["txid"] as? String, let currencyID = UInt32(info["currencyid"] as! String), let networkID = Int(info["networkid"] as! String), let walletIDString = info["walletindex"] as? String {
            let walletID = NSNumber(value: Int32(walletIDString)!)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.getTxAndPresent(with: txID, currencyID, networkID, walletID)
            }
        }
    }
    
    func getTxAndPresent(with txID: String, _ currencyID: UInt32, _ networkID: Int, _ walletID: NSNumber) {
        let mockWallet = createMockWalletForVerbose(currencyID: currencyID, networkID: networkID, walletID: walletID)
        let blockchainType = BlockchainType.init(blockchain: Blockchain.init(currencyID), net_type: networkID)
        
        DataManager.shared.getOneWalletVerbose(wallet: mockWallet) { (wallet, error) in
            if error != nil {
                self.presentAlert(with: error.debugDescription)
            }
            if wallet != nil {
                DataManager.shared.getTransactionHistory(wallet: wallet!, completion: { [unowned self] (history, error) in
                    guard let history = history, let wallet = wallet else {
                        return
                    }
                    
                    let tx = history.filter{ $0.txHash == txID }.first
                    
                    guard let histObj = tx else {
                        return
                    }
                    
                    let storyBoard = UIStoryboard(name: "Wallet", bundle: nil)
                    let transactionVC = storyBoard.instantiateViewController(withIdentifier: "transaction") as! TransactionViewController
                    transactionVC.presenter.histObj = histObj
                    transactionVC.presenter.blockchainType = blockchainType
                    transactionVC.presenter.wallet = wallet
                    
                    self.navigationController?.pushViewController(transactionVC, animated: false)
                })
            }
        }
    }
    
    func createMockWalletForVerbose(currencyID: UInt32, networkID: Int, walletID: NSNumber) -> UserWalletRLM {
        let result = UserWalletRLM()
        result.walletID = walletID
        result.chain = NSNumber(value: currencyID)
        result.chainType = NSNumber(value: networkID)
        return result
    }
}

extension SendWalletsDelegate: SendArrayOfWallets {
    func sendArrOfWallets(arrOfWallets: [UserWalletRLM]) {
        presenter.importedWalletsInDB = arrOfWallets
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}

extension BannersExtension: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
//        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.item == 0 {
            let magicReceiverCell = collectionView.dequeueReusableCell(withReuseIdentifier: "magicReceiverCVCReuseID", for: indexPath) as! MagicReceiverCollectionViewCell
            
            let requestImage = presenter.requestImage
            magicReceiverCell.fillWithBluetoothState(presenter.isBluetoothReachable, requestImage: requestImage)
            
            return magicReceiverCell
        } else if indexPath.item == 1 {
            let assetsCell = collectionView.dequeueReusableCell(withReuseIdentifier: "donatCell", for: indexPath) as! DonationCollectionViewCell
            assetsCell.makeCellBy(index: indexPath.row, assetsInfo: presenter.countFiatMoney())
            return assetsCell
        } else {
            
            let assetsCell = collectionView.dequeueReusableCell(withReuseIdentifier: "donatCell", for: indexPath) as! DonationCollectionViewCell
//            assetsCell.makeCellBy(index: indexPath.row, assetsInfo: presenter.countFiatMoney())
            assetsCell.makeCellBy(index: indexPath.row, assetsInfo: nil)
            return assetsCell
        }
        
        //        let donatCell = collectionView.dequeueReusableCell(withReuseIdentifier: "donatCell", for: indexPath) as! DonationCollectionViewCell
        //        donatCell.makeCellBy(index: indexPath.row, assetsInfo: nil)
        //
        //        return donatCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //        if indexPath.row == 0 {
        //
        //            let customTab = tabBarController as! CustomTabBarViewController
        //            customTab.setSelectIndex(from: customTab.selectedIndex, to: 1)
        //        } else {
        if indexPath.row == 2 {
            unowned let weakSelf =  self
            makeIdForInAppBigBy(indexPath: indexPath)
            makeIdForInAppBy(indexPath: indexPath)
            presentDonationAlertVC(from: weakSelf, with: stringIdForInAppBig)
            (tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
            logAnalytics(indexPath: indexPath)
        }
        //        }
    }
    
    func makeIdForInAppBy(indexPath: IndexPath) {
        switch indexPath.row {
            //        case 1: stringIdForInApp = "io.multy.addingPortfolio5"
        //        case 2: stringIdForInApp = "io.multy.addingCharts5"
        case 0: stringIdForInApp = "io.multy.addingPortfolio5"
        case 1: stringIdForInApp = "io.multy.addingCharts5"
        default: break
        }
    }
    
    func makeIdForInAppBigBy(indexPath: IndexPath) {
        switch indexPath.row {
            //        case 1: stringIdForInAppBig = "io.multy.addingPortfolio50"
        //        case 2: stringIdForInAppBig = "io.multy.addingCharts50"
        case 0: stringIdForInAppBig = "io.multy.addingPortfolio50"
        case 1: stringIdForInAppBig = "io.multy.addingCharts50"
        default: break
        }
    }
    
    func logAnalytics(indexPath: IndexPath) {
        switch indexPath.row {
        case 0: sendDonationAlertScreenPresentedAnalytics(code: donationForPortfolioSC)
        case 1: sendDonationAlertScreenPresentedAnalytics(code: donationForChartsSC)
        default: break
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let firstCell = self.tableView.cellForRow(at: [0,0]) as? BannerTableViewCell else { return }
        let firstCellCollectionView = firstCell.collectionView!
        firstCell.pageControl.currentPage = Int(firstCellCollectionView.contentOffset.x) / Int(firstCellCollectionView.frame.width)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let firstCell = self.tableView.cellForRow(at: [0,0]) as? BannerTableViewCell else { return }
        let firstCellCollectionView = firstCell.collectionView!
        firstCell.pageControl.currentPage = Int(firstCellCollectionView.contentOffset.x) / Int(firstCellCollectionView.frame.width)
    }
}
