//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import RealmSwift
import Alamofire
import CryptoSwift
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

class AssetsViewController: UIViewController, QrDataProtocol, AnalyticsProtocol {
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
    
    let loader = PreloaderView(frame: HUDFrame, text: "", image: #imageLiteral(resourceName: "walletHuge"))
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setpuUI()

        self.performFirstEnterFlow { (succeeded) in
            guard succeeded else {
                return
            }
            
            let isFirst = DataManager.shared.checkIsFirstLaunch()
            if isFirst {
                self.sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: screenFirstLaunch)
                self.view.isUserInteractionEnabled = true
            } else {
                self.sendAnalyticsEvent(screenName: screenMain, eventName: screenMain)
            }
            
            let _ = MasterKeyGenerator.shared.generateMasterKey{_,_, _ in }
            

            self.checkOSForConstraints()
            
//            self.view.addSubview(self.progressHUD)
//            self.progressHUD.hide()
            if self.presenter.account != nil {
                self.tableView.frame.size.height = screenHeight - self.tabBarController!.tabBar.frame.height
            }
            DataManager.shared.socketManager.start()
            DataManager.shared.subscribeToFirebaseMessaging()
            
            //FIXME: add later or refactor
            
            self.successLaunch()
            
            self.openTxFromPush()
        }
    }
    
    func setpuUI() {
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
            DataManager.shared.getServerConfig { (hardVersion, softVersion, err) in
                self.loader.hide()
                
                if hardVersion == nil || softVersion == nil {
                    self.presentUpdateAlert(idOfAlert: 2)
                    completion(true)
                    return
                }
                
                let dictionary = Bundle.main.infoDictionary!
                let buildVersion = (dictionary["CFBundleVersion"] as! NSString).integerValue
                
                if buildVersion < hardVersion! {
                    self.presentUpdateAlert(idOfAlert: 0)
                    completion(false)
                } else if buildVersion < softVersion! {
                    self.presenter.presentSoftUpdate()
                    completion(true)
                } else if softVersion! > hardVersion! && softVersion! > buildVersion {
                    self.presenter.presentSoftUpdate()
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
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: presenter.account == nil)
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        
        if !self.isFirstLaunch || !self.isInternetAvailable {
            self.presenter.updateWalletsInfo(isInternetAvailable: isInternetAvailable)
        }
        self.isFirstLaunch = false
        
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
        
        for counter in 1...100 {
            print(counter)
            print(MasterKeyGenerator.shared.masterKey().masterKey?.base64EncodedString())
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
        if screenHeight == heightOfX {
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
    
    func setupStatusBar() {
        if screenHeight == heightOfX {
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
        
        let portfolioCell = UINib.init(nibName: "PortfolioTableViewCell", bundle: nil)
        self.tableView.register(portfolioCell, forCellReuseIdentifier: "portfolioCell")
        
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
        
        var vc : UIViewController?
        if wallet!.multisigWallet != nil && wallet!.multisigWallet?.deployStatus.intValue != DeployStatus.deployed.rawValue {
            let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
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
    }
    
    func updateUI() {
        tabBarController?.tabBar.frame = presenter.tabBarFrame
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
            let termsVC = storyBoard.instantiateViewController(withIdentifier: "termsVC")
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
            chooseWalletVC.presenter.isNeedToPop = true
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
            navigationController?.pushViewController(joinVC, animated: true)
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
                sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: createFirstWalletTap)
//                self.performSegue(withIdentifier: "createWalletVC", sender: Any.self)
                self.presenter.makeAuth { (answer) in
                    self.presenter.createFirstWallets(blockchianType: BlockchainType.create(currencyID: 0, netType: 0), completion: { (answer, err) in
                        self.presenter.createFirstWallets(blockchianType: BlockchainType.create(currencyID: 60, netType: 1), completion: { (answer, err) in
                            self.presenter.getWalletsVerbose(completion: { (complete) in
                                
                            })
                        })
                    })
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
                sendAnalyticsEvent(screenName: screenFirstLaunch, eventName: restoreMultyTap)
                let storyboard = UIStoryboard(name: "SeedPhrase", bundle: nil)
                let backupSeedVC = storyboard.instantiateViewController(withIdentifier: "backupSeed") as! CheckWordsViewController
                backupSeedVC.isRestore = true
                self.navigationController?.pushViewController(backupSeedVC, animated: true)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath {
        case [0,0]:         // PORTFOLIO CELL  or LOGO
            if presenter.account == nil {
                return 220
            } else {
                if presenter.account!.isSeedPhraseSaved() {
                    return 340
                } else {
                    return 340 + Constants.AssetsScreen.backupAssetsOffset
                }
            }
        case [0,1]:        // !!!NEW!!! WALLET CELL
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
                    return 340
                } else {
                    return 340 + Constants.AssetsScreen.backupAssetsOffset
                }
            }
        case [0,1]:        // !!!NEW!!! WALLET CELL
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
            return 4                                         // logo / empty cell / create wallet / restore
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath {
        case [0,0]:         // PORTFOLIO CELL  or LOGO
            if presenter.account == nil {
                let logoCell = self.tableView.dequeueReusableCell(withIdentifier: "logoCell") as! LogoTableViewCell
                return logoCell
            } else {
                let portfolioCell = self.tableView.dequeueReusableCell(withIdentifier: "portfolioCell") as! PortfolioTableViewCell
                portfolioCell.mainVC = self
                portfolioCell.delegate = self
                
                return portfolioCell
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
    }
}

extension CollectionViewDelegateFlowLayout : UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: screenWidth, height: 277 /* (screenWidth / 375.0)*/)
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

extension CollectionViewDelegate : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        unowned let weakSelf =  self
        makeIdForInAppBigBy(indexPath: indexPath)
        makeIdForInAppBy(indexPath: indexPath)
        self.presentDonationAlertVC(from: weakSelf, with: stringIdForInAppBig)
        (tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        logAnalytics(indexPath: indexPath)
    }
    
    func makeIdForInAppBy(indexPath: IndexPath) {
        switch indexPath.row {
        case 0: stringIdForInApp = "io.multy.addingPortfolio5"
        case 1: stringIdForInApp = "io.multy.addingCharts5"
        default: break
        }
    }
    
    func makeIdForInAppBigBy(indexPath: IndexPath) {
        switch indexPath.row {
        case 0: stringIdForInAppBig = "io.multy.addingPortfolio50"
        case 1: stringIdForInAppBig = "io.multy.addingCharts50"
        default: break
        }
    }
    
    func logAnalytics(indexPath: IndexPath) {
        let eventCode = indexPath.row == 0 ? donationForPortfolioSC : donationForChartsSC
        sendDonationAlertScreenPresentedAnalytics(code: eventCode)
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard let firstCell = self.tableView.cellForRow(at: [0,0]) as? PortfolioTableViewCell else { return }
        let firstCellCollectionView = firstCell.collectionView!
        firstCell.pageControl.currentPage = Int(firstCellCollectionView.contentOffset.x) / Int(firstCellCollectionView.frame.width)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        guard let firstCell = self.tableView.cellForRow(at: [0,0]) as? PortfolioTableViewCell else { return }
        let firstCellCollectionView = firstCell.collectionView!
        firstCell.pageControl.currentPage = Int(firstCellCollectionView.contentOffset.x) / Int(firstCellCollectionView.frame.width)
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
            let walletID = NSNumber(value: Int(walletIDString)!)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.getTxAndPresent(with: txID, currencyID, networkID, walletID)
            }
        }
    }
    
    func getTxAndPresent(with txID: String, _ currencyID: UInt32, _ networkID: Int, _ walletID: NSNumber) {
        let blockchainType = BlockchainType.init(blockchain: Blockchain.init(currencyID), net_type: networkID)
        
        DataManager.shared.getOneWalletVerbose(walletID: walletID, blockchain: blockchainType) { (wallet, error) in
            if error != nil {
                self.presentAlert(with: error.debugDescription)
            }
            let networkNumber = NSNumber(value: networkID)
            let currencyNumber = NSNumber(value: currencyID)
            DataManager.shared.getTransactionHistory(currencyID: currencyNumber, networkID: networkNumber, walletID: walletID, completion: { (history, error) in
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

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}
