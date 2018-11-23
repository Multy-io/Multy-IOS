//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details
import UIKit
import WebKit
import JavaScriptCore
import Result
//typealias ResultDapp<T, Error: Swift.Error> = Result

private typealias LocalizeDelegate = BrowserViewController

protocol BrowserNavigationBarDelegate: class {
    func did(action: BrowserNavigation)
}

enum BrowserAction {
    case navigationAction(BrowserNavigation)
}

protocol BrowserViewControllerDelegate: class {
    func runAction(action: BrowserAction)
    func didVisitURL(url: URL, title: String)
}

class BrowserViewController: UIViewController, AnalyticsProtocol {
    
    private var myContext = 0
    var wallet = UserWalletRLM() {
        didSet {
            if wallet.id.isEmpty == false {
                DataManager.shared.getWallet(primaryKey: self.wallet.id) { [unowned self] in
                    switch $0 {
                    case .success(let wallet):
                        self.wallletFromDB = wallet
                        
                        self.wallet.importedPrivateKey = self.wallletFromDB.importedPrivateKey
                        self.wallet.importedPublicKey = self.wallletFromDB.importedPublicKey
                    case .failure(_):
                        break
                    }
                }
            }
        }
    }
        
    var wallletFromDB = UserWalletRLM()
    
    var urlString = String()
    var alert: UIAlertController?
    
    private struct Keys {
        static let estimatedProgress = "estimatedProgress"
        static let developerExtrasEnabled = "developerExtrasEnabled"
        static let URL = "URL"
        static let ClientName = "Trust"
    }
    
    private lazy var userClient: String = {
        return Keys.ClientName + "/" + (Bundle.main.versionNumber ?? "")
    }()
    //
    lazy var webView: WKWebView = {
        let webView = WKWebView(
            frame: .zero,
            configuration: self.config
        )
        webView.allowsBackForwardNavigationGestures = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        
        if isDebug {
            webView.configuration.preferences.setValue(true, forKey: Keys.developerExtrasEnabled)
//            webView.configuration.preferences.setValue(true, forKey: WKWebsiteDataTypeOfflineWebApplicationCache)
        }
        
        return webView
    }()
    
    weak var delegate: BrowserViewControllerDelegate?
    
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tintColor = UIColor(hex: "3375BB")
        progressView.trackTintColor = .clear
        
        return progressView
    }()
    
    lazy var config: WKWebViewConfiguration = {
        //TODO
        let config = WKWebViewConfiguration.make(for: wallet,
                                                 in: ScriptMessageMediator(delegate: self))
        config.websiteDataStore =  WKWebsiteDataStore.default()
        
        config.allowsInlineMediaPlayback = true
        config.suppressesIncrementalRendering = true
        
        return config
    }()
    
    var lastTxID = ""
    
    
    init(wallet: UserWalletRLM, urlString: String) {
        self.wallet = wallet
        self.urlString = urlString
        
        super.init(nibName: nil, bundle: nil)
        
        view.addSubview(webView)
        injectUserAgent()
        
        webView.addSubview(progressView)
        webView.bringSubview(toFront: progressView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.layoutGuide.topAnchor),// topLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),// bottomLayoutGuide.topAnchor),
            
            progressView.topAnchor.constraint(equalTo: view.layoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
            ])
        view.backgroundColor = .white
        webView.addObserver(self, forKeyPath: Keys.estimatedProgress, options: .new, context: &myContext)
        webView.addObserver(self, forKeyPath: Keys.URL, options: [.new, .initial], context: &myContext)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshURL()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleTransactionUpdatedNotification(notification :)), name: NSNotification.Name("transactionUpdated"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("transactionUpdated"), object: nil)
    }
    
    private func injectUserAgent() {
        webView.evaluateJavaScript("navigator.userAgent") { [weak self] result, _ in
            guard let `self` = self, let currentUserAgent = result as? String else { return }
            self.webView.customUserAgent = currentUserAgent + " " + self.userClient
        }
    }
    
    @objc fileprivate func handleTransactionUpdatedNotification(notification : Notification) {
        DispatchQueue.main.async { [unowned self] in
            print(notification)
            
            let msg = notification.userInfo?["NotificationMsg"] as? [AnyHashable : Any]
            guard msg != nil, let txID = msg!["txid"] as? String else {
                return
            }
            
            if txID == self.lastTxID {
//                self.webView.reload()
                self.webView.scrollView.setContentOffset(CGPoint.zero, animated: true)
            }
            
            self.lastTxID = ""
        }
    }
    
    func goTo(url: URL) {
        webView.load(URLRequest(url: url))
    }
    
    func goHome() {
        let linkString = urlString //"https://dragonereum-alpha-test.firebaseapp.com"  //"https://app.alpha.dragonereum.io"
        guard let url = URL(string: linkString) else { return } //"https://dapps.trustwalletapp.com/"
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
//        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        webView.load(request)
//        browserNavBar?.textField.text = url.absoluteString
    }
    
    func reload() {
        webView.reload()
        self.webView.scrollView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    private func stopLoading() {
        webView.stopLoading()
    }
    
    private func refreshURL() {
        if let url = webView.url?.absoluteURL {
            delegate?.didVisitURL(url: url, title: "Go")
        }
    }
    
    private func recordURL() {
        guard let url = webView.url else {
            return
        }
        delegate?.didVisitURL(url: url, title: webView.title ?? "")
    }
    
    private func changeURL(_ url: URL) {
//        delegate?.runAction(action: .changeURL(url))
        refreshURL()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard let change = change else { return }
        if context != &myContext {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        if keyPath == Keys.estimatedProgress {
            if let progress = (change[NSKeyValueChangeKey.newKey] as AnyObject).floatValue {
                progressView.progress = progress
                progressView.isHidden = progress == 1
            }
        } else if keyPath == Keys.URL {
            if let url = webView.url {
//                self.browserNavBar?.textField.text = url.absoluteString
                changeURL(url)
            }
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: Keys.estimatedProgress)
        webView.removeObserver(self, forKeyPath: Keys.URL)
    }
}

extension BrowserViewController: BrowserNavigationBarDelegate {
    func did(action: BrowserNavigation) {
        delegate?.runAction(action: .navigationAction(action))
        switch action {
        case .goBack:
            break
        case .more:
            break
        case .home:
            break
        case .enter:
            break
        case .beginEditing:
            stopLoading()
        }
    }
}

extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        recordURL()
//        hideErrorView()
        refreshURL()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
//        hideErrorView()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
//        handleError(error: error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
//        handleError(error: error)
    }
}

extension BrowserViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let body = message.body as! Dictionary<String, Any>
        
        guard let name = body["name"] as? String else {
            //FIXME: callback for WebView?
            return
        }
        
        guard let operationType = DappOperationType.init(rawValue: name) else {
            return
        }
        
        guard let objectData = body["object"] as? Dictionary<String, Any> else {
            return
        }
        
        
        let operationObject = OperationObject.init(with: objectData)
        
        switch operationType {
        case .signTransaction:
            showAlert(with: operationObject)
        case .signMessage:
            return
        case .signPersonalMessage:
            return
        case .signTypedMessage:
            return
        }
    }
}


//perfom operations
extension BrowserViewController {
    func refreshWalletAndSendTx(for object: OperationObject) {
        DataManager.shared.getOneWalletVerbose(wallet: wallet) { [unowned self] (wallet, error) in
            if error != nil {
//                self.webView.reload()
                self.webView.scrollView.setContentOffset(CGPoint.zero, animated: true)
                self.presentAlert(for: "") // default message
            } else {
                self.wallet = wallet!
                self.signTx(for: object)
            }
        }
    }
    
    func showAlert(with txInfo: OperationObject) {
        let localizedFormatString = localize(string: Constants.browserTxAlertSring)
        let valueString = BigInt("\(txInfo.value)").cryptoValueString(for: wallet.blockchain)
        let feeString = (BigInt("\(txInfo.gasLimit)") * BigInt("\(txInfo.gasPrice)")).cryptoValueString(for: wallet.blockchain)
        
        let message = NSString.init(format: NSString.init(string: localizedFormatString),  valueString, feeString, wallet.name)
        let alert = UIAlertController(title: nil, message: message as String, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: localize(string: Constants.denyString), style: .default, handler: { [weak self] (action) in
            if self != nil {
//                self!.webView.reload()
                self!.webView.scrollView.setContentOffset(CGPoint.zero, animated: true)
            }
        }))
        
        alert.addAction(UIAlertAction(title: localize(string: Constants.confirmString), style: .cancel, handler: { [weak self] (action) in
            if self != nil {
                self!.refreshWalletAndSendTx(for: txInfo)
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func signTx(for object: OperationObject) {
//        let account = DataManager.shared.realmManager.account
//        let core = DataManager.shared.coreLibManager
//        var binaryData = account!.binaryDataString.createBinaryData()!
        
//        var addressData = Dictionary<String, Any>()
//
//        if wallletFromDB.isImportedForPrimaryKey {
//            if wallletFromDB.importedPrivateKey.isEmpty == false {
//                let data = DataManager.shared.coreLibManager.createPublicInfo(blockchainType: wallletFromDB.blockchainType, privateKey: wallletFromDB.importedPrivateKey)
//                switch data {
//                case .success(let dict):
//                    addressData = dict
//                case .failure(let error):
//                    //FIXME: add ALERT
//                    break
//                }
//            } else {
//                //FIXME: add ALERT
//            }
//        } else {
//            addressData = core.createAddress(blockchainType:    wallet.blockchainType,
//                                             walletID:          wallet.walletID.uint32Value,
//                                             addressID:         wallet.changeAddressIndex,
//                                             binaryData:        &binaryData)!
//        }
        
        let dappPayload = object.hexData
        
        let trData = DataManager.shared.createETHTransaction(wallet: wallet,
                                                             sendAmountString: object.value,
                                                             destinationAddress: object.toAddress,
                                                             gasPriceAmountString: "\(object.gasPrice)",
                                                             gasLimitAmountString: "\(object.gasLimit)",
                                                             payload: dappPayload)
        
//        let trData2 = DataManager.shared.coreLibManager.createEtherTransaction(addressPointer: addressData["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
//                                                                              sendAddress: object.toAddress,
//                                                                              sendAmountString: object.value,
//                                                                              nonce: wallet.ethWallet!.nonce.intValue,
//                                                                              balanceAmount: wallet.ethWallet!.balance,
//                                                                              ethereumChainID: UInt32(wallet.blockchainType.net_type),
//                                                                              gasPrice: "\(object.gasPrice)",
//                                                                              gasLimit: "\(object.gasLimit)",
//                                                                              payload: dappPayload)
        let rawTransaction = trData.message
        
        guard trData.isTransactionCorrect else {
//            self.webView.reload()
            self.presentAlert(for: rawTransaction)
            
            return
        }
        
        let newAddressParams = [
            "walletindex"   : wallet.walletID.intValue,
            "address"       : wallet.address,
            "addressindex"  : 0,
            "transaction"   : rawTransaction,
            "ishd"          : wallet.shouldCreateNewAddressAfterTransaction
            ] as [String : Any]
        
        let params = [
            "currencyid": wallet.chain,
            /*"JWT"       : jwtToken,*/
            "networkid" : wallet.chainType,
            "payload"   : newAddressParams
            ] as [String : Any]
        
        DataManager.shared.sendHDTransaction(transactionParameters: params) { [unowned self] (dict, error) in
            if dict != nil {
                self.saveLastTXID(from:  dict!)
                
                self.showSuccessAlert()
//                self.webView.reload()
                self.webView.scrollView.setContentOffset(CGPoint.zero, animated: true)
                
                let amountString = BigInt("\(object.value)").cryptoValueString(for: self.wallet.blockchain)
                self.sendDappAnalytics(screenName: browserTx, params: self.makeAnalyticsParams(sendAmountString: amountString,
                                                                                               gasPrice: "\(object.gasPrice)",
                                                                                               gasLimit: "\(object.gasLimit)",
                                                                                               contractMethod: String(dappPayload.prefix(8))))
            } else {
                self.presentAlert(for: "")
//                self.webView.reload()
                self.webView.scrollView.setContentOffset(CGPoint.zero, animated: true)
            }
        }
    }
    
    func makeAnalyticsParams(sendAmountString: String, gasPrice: String, gasLimit: String, contractMethod: String) -> NSDictionary {
        let params: NSDictionary = [
            "dAppURL" :         webView.url != nil ? webView.url!.absoluteString : "empty URL",
            "Blockchain":       wallet.chain,
            "NetType" :         wallet.chainType,
            "Amount" :          sendAmountString,
            "GasPrice" :        gasPrice,
            "GasLimit" :        gasLimit,
            "ContractMethod":   contractMethod
        ]
        
        return params
    }
    
    func showSuccessAlert() {
        // show success alert
        alert = UIAlertController(title: "", message: Constants.successString, preferredStyle: .alert)
        present(self.alert!, animated: true, completion: nil)
        let when = DispatchTime.now() + 2
        DispatchQueue.main.asyncAfter(deadline: when){ [unowned self] in
            if let alert = self.alert {
                alert.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func presentAlert(for info: String) {
        var message = String()
        if info.hasPrefix("BigInt value is not representable as") {
            message = Constants.youEnteredTooSmallAmountString
        } else if info.hasPrefix("Transaction is trying to spend more than available") {
            message = Constants.youTryingSpendMoreThenHaveString
        } else {
            message = Constants.somethingWentWrongString
        }
        
        let alert = UIAlertController(title: localize(string: Constants.errorString), message: localize(string: message), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in }))
        present(alert, animated: true, completion: nil)
    }
    
    func saveLastTXID(from info: NSDictionary) {
        guard let code = info["code"] as? Int, code == 200 else {
            return
        }
        
        guard let message = info["message"] as? NSDictionary else {
            return
        }
        
        guard let txID = message["message"] as? String else {
            return
        }
        
        lastTxID = txID
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "DappBrowser"
    }
}
