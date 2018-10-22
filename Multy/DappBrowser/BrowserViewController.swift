//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import WebKit
import JavaScriptCore
import Result
//typealias ResultDapp<T, Error: Swift.Error> = Result

enum BrowserAction {
    case history
    //    case addBookmark(bookmark: Bookmark)
    case bookmarks
    case qrCode
    case changeURL(URL)
    case navigationAction(BrowserNavigation)
}

protocol BrowserViewControllerDelegate: class {
    func didCall(action: DappAction, callbackID: Int)
    func runAction(action: BrowserAction)
    func didVisitURL(url: URL, title: String)
}

class BrowserViewController: UIViewController {
    
    private var myContext = 0
    //    let account: WalletInfo
    //    let sessionConfig: Config
    
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
        }
        return webView
    }()
    
    lazy var errorView: BrowserErrorView = {
        let errorView = BrowserErrorView()
        errorView.translatesAutoresizingMaskIntoConstraints = false
        errorView.delegate = self
        return errorView
    }()
    
    weak var delegate: BrowserViewControllerDelegate? {
        didSet {
            print("\noldValue: \(oldValue)\nnewValue: \(delegate)\n")
        }
    }
    
    var browserNavBar: BrowserNavigationBar? {
        return navigationController?.navigationBar as? BrowserNavigationBar
    }
    
    lazy var progressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tintColor = Colors.darkBlue
        progressView.trackTintColor = .clear
        return progressView
    }()
    
    //    //Take a look at this issue : https://stackoverflow.com/questions/26383031/wkwebview-causes-my-view-controller-to-leak
    lazy var config: WKWebViewConfiguration = {
        //TODO
        let config = WKWebViewConfiguration.make(for: "0xf946d8b85f4e53a375daeeb9111043f107b013a1",
                                                 in: ScriptMessageProxy(delegate: self))
        config.websiteDataStore = WKWebsiteDataStore.default()
        return config
    }()
    
    
    init(
        //        account: WalletInfo,
        //        config: Config
        //        server: RPCServer
        ) {
        //        self.account = account
        //        self.sessionConfig = config
        //        self.server = server
        
        super.init(nibName: nil, bundle: nil)
        
        view.addSubview(webView)
        injectUserAgent()
        
        webView.addSubview(progressView)
        webView.bringSubview(toFront: progressView)
        view.addSubview(errorView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.layoutGuide.topAnchor),// topLayoutGuide.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),// bottomLayoutGuide.topAnchor),
            
            progressView.topAnchor.constraint(equalTo: view.layoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            errorView.topAnchor.constraint(equalTo: webView.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            ])
        view.backgroundColor = .white
        webView.addObserver(self, forKeyPath: Keys.estimatedProgress, options: .new, context: &myContext)
        webView.addObserver(self, forKeyPath: Keys.URL, options: [.new, .initial], context: &myContext)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //        fatalError("init(coder:) has not been implemented")
    }
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        refreshURL()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    //    func logAnalytics() {
    //        sendDonationAlertScreenPresentedAnalytics(code: donationForActivitySC)
    //    }
    
    /////////
    private func injectUserAgent() {
        webView.evaluateJavaScript("navigator.userAgent") { [weak self] result, _ in
            guard let `self` = self, let currentUserAgent = result as? String else { return }
            self.webView.customUserAgent = currentUserAgent + " " + self.userClient
        }
    }
    
    func goTo(url: URL) {
        webView.load(URLRequest(url: url))
    }
    
    //COMMENTED
//        func notifyFinish(callbackID: Int, value: ResultDapp<DappCallback, DAppError>) {
//            let script: String = {
//                switch value {
//                case .success(let result):
//                    return "executeCallback(\(callbackID), null, \"\(result.value.object)\")"
//                case .failure(let error):
//                    return "executeCallback(\(callbackID), \"\(error)\", null)"
//                }
//            }()
//            webView.evaluateJavaScript(script, completionHandler: nil)
//        }
    
    func goHome() {
        let linkString = "https://dragonereum-alpha-test.firebaseapp.com"  //"https://app.alpha.dragonereum.io"
        guard let url = URL(string: linkString) else { return } //"https://dapps.trustwalletapp.com/"
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        hideErrorView()
        webView.load(request)
        browserNavBar?.textField.text = url.absoluteString
    }
    
    func reload() {
        hideErrorView()
        webView.reload()
    }
    
    private func stopLoading() {
        webView.stopLoading()
    }
    
    private func refreshURL() {
        browserNavBar?.textField.text = webView.url?.absoluteString
        browserNavBar?.backButton.isHidden = !webView.canGoBack
        
    }
    
    private func recordURL() {
        guard let url = webView.url else {
            return
        }
        delegate?.didVisitURL(url: url, title: webView.title ?? "")
    }
    
    private func changeURL(_ url: URL) {
        delegate?.runAction(action: .changeURL(url))
        refreshURL()
    }
    
    private func hideErrorView() {
        errorView.isHidden = true
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
                self.browserNavBar?.textField.text = url.absoluteString
                changeURL(url)
            }
        }
    }
    
    deinit {
        webView.removeObserver(self, forKeyPath: Keys.estimatedProgress)
        webView.removeObserver(self, forKeyPath: Keys.URL)
    }
    
    func addBookmark() {
        guard let url = webView.url?.absoluteString else { return }
        guard let title = webView.title else { return }
        //COMMENTED:
        //        delegate?.runAction(action: .addBookmark(bookmark: Bookmark(url: url, title: title)))
    }
    
    @objc private func showBookmarks() {
        delegate?.runAction(action: .bookmarks)
    }
    
    @objc private func history() {
        delegate?.runAction(action: .history)
    }
    
    func handleError(error: Error) {
        if error.code == NSURLErrorCancelled {
            return
        } else {
            if error.domain == NSURLErrorDomain,
                let failedURL = (error as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? URL {
                changeURL(failedURL)
            }
            errorView.show(error: error)
        }
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
        hideErrorView()
        refreshURL()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        hideErrorView()
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        handleError(error: error)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        handleError(error: error)
    }
}

extension BrowserViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        //COMMENTED
//                guard let command = DappAction.fromMessage(message) else { return }
        //        let requester = DAppRequester(title: webView.title, url: webView.url)
        //        //TODO: Refactor
        //        let token = TokensDataStore.token(for: server)
        //        let transfer = Transfer(server: server, type: .dapp(token, requester))
        //        let action = DappAction.fromCommand(command, transfer: transfer)
        //
        //        delegate?.didCall(action: action, callbackID: command.id)
        
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
            signTx(for: operationObject)
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
    func signTx(for object: OperationObject) {
        let account = DataManager.shared.realmManager.account
        let core = DataManager.shared.coreLibManager
        var binaryData = account!.binaryDataString.createBinaryData()!
        
        DataManager.shared.getWallet(primaryKey: "c6124b7e456281fbef3d39dacdebb0cda9102fea8c05cc863028db934c903ffe") {
            switch $0 {
            case .success(let wallet):
                let addressData = core.createAddress(blockchainType:    wallet.blockchainType,
                                                     walletID:          wallet.walletID.uint32Value,
                                                     addressID:         wallet.changeAddressIndex,
                                                     binaryData:        &binaryData)
                
                let trData = DataManager.shared.coreLibManager.createEtherTransaction(addressPointer: addressData!["addressPointer"] as! UnsafeMutablePointer<OpaquePointer?>,
                                                                                      sendAddress: object.toAddress,
                                                                                      sendAmountString: "\(object.value)",
                    nonce: wallet.ethWallet!.nonce.intValue,
                    balanceAmount: wallet.ethWallet!.balance,
                    ethereumChainID: UInt32(wallet.blockchainType.net_type),
                    gasPrice: "\(object.gasPrice)",
                    gasLimit: "\(object.gasLimit)",
                    payload: object.hexData)
                let rawTransaction = trData.message
                
                let newAddressParams = [
                    "walletindex"   : wallet.walletID.intValue,
                    "address"       : addressData!["address"] as! String,
                    "addressindex"  : wallet.addresses.count,
                    "transaction"   : rawTransaction,
                    "ishd"          : wallet.shouldCreateNewAddressAfterTransaction
                    ] as [String : Any]
                
                let params = [
                    "currencyid": wallet.chain,
                    /*"JWT"       : jwtToken,*/
                    "networkid" : wallet.chainType,
                    "payload"   : newAddressParams
                    ] as [String : Any]
                
                DataManager.shared.sendHDTransaction(transactionParameters: params, completion: { (dict, error) in
                    print(dict)
                })
                
            case .failure(let error):
                print(print(error))
            }
        }
    }
}

extension BrowserViewController: BrowserErrorViewDelegate {
    func didTapReload(_ sender: Button) {
        reload()
    }
}
