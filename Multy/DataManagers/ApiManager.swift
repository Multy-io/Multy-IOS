//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Alamofire
import FirebaseMessaging
//import MultyCoreLibrary

class AccessTokenAdapter: RequestAdapter {
    private let accessToken: String
    
    init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        var urlRequest = urlRequest
        
        if let urlString = urlRequest.url?.absoluteString, urlString.hasPrefix("\(apiUrl)api/v1/") {
            urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        }
        
        return urlRequest
    }
}

class ApiManager: NSObject, RequestRetrier {
    static let shared = ApiManager()
    var requestManager = Alamofire.SessionManager.default
    var token = String() {
        didSet {
            self.requestManager.adapter = AccessTokenAdapter(accessToken: token)
        }
    }
    var userID = String()    
    var pushToken: String {
        get {
            return Messaging.messaging().fcmToken ?? ""
        }
    }
    
    var topVC: UIViewController?
    var noConnectionView: UIView?
    
    override init() {
        super.init()
        
//        let configuration = URLSessionConfiguration.default
//        configuration.timeoutIntervalForRequest = 10 // seconds
//        configuration.timeoutIntervalForResource = 10
        
//        requestManager = Alamofire.SessionManager(configuration: configuration)
        let serverTrustPolicies: [String: ServerTrustPolicy] = [
//            "api.multy.io": .pinCertificates(
//                certificates: ServerTrustPolicy.certificates(),
//                validateCertificateChain: true,
//                validateHost: true
//            ),
            shortURL : .disableEvaluation
            ]
        
        requestManager = SessionManager(serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies))
        
        requestManager.retrier = self
        requestManager.adapter = AccessTokenAdapter(accessToken: token)
        
        let currentTabIndex = (UIApplication.shared.keyWindow?.rootViewController as? CustomTabBarViewController)?.selectedIndex
        topVC = UIApplication.shared.keyWindow?.rootViewController?.childViewControllers[currentTabIndex!].childViewControllers.last
        noConnectionView = topVC?.noConnectionView()
    }
    
//    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
//        if let urlString = urlRequest.url?.absoluteString {
//            if urlString.hasPrefix("\(apiUrl)server/config") || false {
//
//            }
//        }
//    }
    
    public func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        print("\n\n\n\n\n\nretrier: \(request.request?.urlRequest?.url?.absoluteString)\n\n\n\n\n\n")
        
        getServerConfig { (answer, error) in
            if answer != nil && error == nil {
                self.topVC?.removeNoConnection(view: self.noConnectionView!)
                if let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 {
                    if self.userID.isEmpty {
                        DispatchQueue.main.async {
                            DataManager.shared.getAccount { (acc, err) in
                                if acc != nil {
                                    self.userID = acc!.userID
                                }
                                completion(false, 0.0)
                            }
                        }
                    }

                    var params : Parameters = [ : ]

                    params["userID"] = self.userID
                    params["deviceID"] = "iOS \(UIDevice.current.name)"
                    params["deviceType"] = 1
                    params["pushToken"] = self.pushToken
                    params["appVersion"] = ((infoPlist["CFBundleShortVersionString"] as! String) + " " + (infoPlist["CFBundleVersion"] as! String))

                    self.auth(with: params, completion: { (dict, error) in
                        completion(true, 0.2) // retry after 0.2 second
                    })
                } else {
                    completion(false, 0.0) // don't retry
                }
                
                
            } else {
                //block UI
                self.presentServerOff()
                print("\n\n\n\n\n\nBlock\n\n\n\n")
            }
        }
    }
    
    func presentServerOff() {
        let currentTabIndex = (UIApplication.shared.keyWindow?.rootViewController as? CustomTabBarViewController)?.selectedIndex
        topVC = UIApplication.shared.keyWindow?.rootViewController?.childViewControllers[currentTabIndex!]//.childViewControllers.last
        noConnectionView = topVC?.noConnectionView()
        noConnectionView?.alpha = 0
//        let storyboard = UIStoryboard(name: "Main", bundle: nil)
//        let slpashScreen = storyboard.instantiateViewController(withIdentifier: "splash") as! SplashViewController
//        slpashScreen.isJailAlert = 2
//        slpashScreen.parentVC = topVC
//        slpashScreen.modalPresentationStyle = .overCurrentContext
//        topVC!.present(slpashScreen, animated: true, completion: nil)
        if topVC != nil && topVC!.isNoConnectionOnScreen() {
            return
        }
        currentStatusStyle = .lightContent
        topVC!.setNeedsStatusBarAppearanceUpdate()
        topVC!.view.addSubview(noConnectionView!)
        UIView.animate(withDuration: 0.5) {
            self.noConnectionView?.alpha = 1.0
        }
        autoConnect()
    }
    
    var timer = Timer()
    
    func autoConnect() {
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.reconnect), userInfo: nil, repeats: true)
    }
    
    @objc func reconnect() {
        getServerConfig(completion: { (nsd, error) in
            if error == nil {
                self.timer.invalidate()
                self.removeNoConnection()
            }
        })
    }
    
    func removeNoConnection() {
        if topVC!.isNoConnectionOnScreen() {
            UIView.animate(withDuration: 0.5, animations: {
                self.noConnectionView?.alpha = 0.0
            }) { (ended) in
                currentStatusStyle = .default
                self.topVC!.removeNoConnection(view: self.noConnectionView!)
            }
        }
    }
    
    func getServerConfig(completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        requestManager.request("\(apiUrl)server/config", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                print("\n\nXXXXXX\nGETING SERVER CONFIG\nXXXXXXX\nTRUE")
                isServerConnectionExist = true
                if response.result.value != nil {
                    completion(response.result.value as? NSDictionary, nil)
                }
            case .failure(_):
                print("\n\nXXXXXX\nGETING SERVER CONFIG\nXXXXXXX\nFALSE")
                isServerConnectionExist = false
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func auth(with parameters: Parameters, completion: @escaping (_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        requestManager.request("\(apiUrl)auth", method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: header).debugLog().responseJSON { [weak self] (response: DataResponse<Any>) in
            
            print("----------------------AUTH")
            
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    isServerConnectionExist = true
                    if let token = (response.result.value as! NSDictionary)["token"] as? String {
                        DataManager.shared.updateToken(token)
                        self!.token = token
                    }
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                isServerConnectionExist = false
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func getAssets(completion: @escaping (_ holdings: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
            
        ]
        
        requestManager.request("\(apiUrl)api/v1/wallets", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func restoreMemamaskWallets(walletsInfo: Parameters, completion: @escaping (_ isSuccess: Bool) -> ()) {
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/discover/wallets", method: .post, parameters: walletsInfo, encoding: JSONEncoding.default, headers: header).debugLog().validate().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.error == nil {
                    completion(true)
                } else {
                    completion(false)
                }
            case .failure(_):
                completion(false)
            }
        }
    }
    
    func getTransactionInfo(transactionString: String, completion: @escaping (_ answer: HistoryRLM?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        //MARK: USD
        requestManager.request("\(apiUrl)api/v1/gettransactioninfo/\(transactionString)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    let tx = HistoryRLM.initWithInfo(historyDict: response.result.value as! NSDictionary)
                    completion((tx), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func importWallet(_ walletDict: Parameters, completion: @escaping (_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/wallet", method: .post, parameters: walletDict, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                
                print("api/v1/wallet: \(response.result.value)")
                if response.result.value != nil {
                    if ((response.result.value! as! NSDictionary) ["code"] != nil) {
                        completion(response.result.value as! NSDictionary, nil)
                    } else {
                        completion(nil, nil)
                    }
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func addWallet(_ walletDict: Parameters, completion: @escaping (_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/wallet", method: .post, parameters: walletDict, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                print("api/v1/wallet: \(response.result.value)")
                if response.result.value != nil {
                    if ((response.result.value! as! NSDictionary) ["code"] != nil) {
                        completion(NSDictionary(), nil)
                    } else {
                        completion(nil, nil)
                    }
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func deleteCreatedWallet(currencyID: NSNumber, networkID: NSNumber, walletIndex: NSNumber, completion: @escaping (Result<NSDictionary, String>) -> ()) {
        let header: HTTPHeaders = [
            "Authorization" : "Bearer \(self.token)"
        ]
        requestManager.request("\(apiUrl)api/v1/wallet/\(currencyID)/\(networkID)/\(walletIndex)/\(WalletType.Created.rawValue)", method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    print(response.result.value as! NSDictionary)
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(_):
                completion(Result.failure(response.result.error!.localizedDescription))
                break
            }
        }
    }
    
    func deleteImportedWallet(currencyID: NSNumber, networkID: NSNumber, address: String, completion: @escaping (Result<NSDictionary, String>) -> ()) {
        let header: HTTPHeaders = [
            "Authorization" : "Bearer \(self.token)"
        ]
        requestManager.request("\(apiUrl)api/v1/wallet/\(currencyID)/\(networkID)/\(address)/\(WalletType.Imported.rawValue)", method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    print(response.result.value as! NSDictionary)
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(_):
                completion(Result.failure(response.result.error!.localizedDescription))
                break
            }
        }
    }
    
    func addAddress(_ walletDict: Parameters, completion: @escaping (_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/address", method: .post, parameters: walletDict, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func getFeeRate(currencyID: UInt32, networkID: UInt32, ethAddress: String?, completion: @escaping (_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        var url = ""
        if ethAddress != nil {
            url = "\(apiUrl)api/v1/transaction/feerate/\(currencyID)/\(networkID)/\(ethAddress!)"
        } else {
            url = "\(apiUrl)api/v1/transaction/feerate/\(currencyID)/\(networkID)"
        }
        
        //MARK: USD
        requestManager.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    print("FeeRates Answer: \n\n \(response.result.value)")
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                if let data = response.data {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] {
                        print(json)
                    }
                }
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func getWalletsVerbose(completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        DataManager.shared.getAccount(completion: { (acc, err) in
            if acc != nil {
                self.token = acc!.token
            }
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        self.requestManager.request("\(apiUrl)api/v1/wallets/verbose", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
        })
    }
    
    func getOneCreatedWalletVerbose(walletID: NSNumber, blockchain: BlockchainType, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        //MARK: add chain ID
        requestManager.request("\(apiUrl)api/v1/wallet/\(walletID)/verbose/\(blockchain.blockchain.rawValue)/\(blockchain.net_type)/\(WalletType.Created.rawValue)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func getOneMultisigWalletVerbose(inviteCode: String, blockchain: BlockchainType, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        //MARK: add chain ID
        requestManager.request("\(apiUrl)api/v1/wallet/\(inviteCode)/verbose/\(blockchain.blockchain.rawValue)/\(blockchain.net_type)/\(WalletType.Multisig.rawValue)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func getOneImportedWalletVerbose(address: String, blockchain: BlockchainType, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        //MARK: add chain ID
        requestManager.request("\(apiUrl)api/v1/wallet/\(address)/verbose/\(blockchain.blockchain.rawValue)/\(blockchain.net_type)/\(WalletType.Imported.rawValue)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func sendRawTransaction(walletID: NSNumber, transactionParameters: Parameters, completion: @escaping (_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        //MARK: TESTNET - send currency is 1
        requestManager.request("\(apiUrl)api/v1/transaction/send/\(walletID)", method: .post, parameters: transactionParameters, encoding: JSONEncoding.default, headers: header).validate().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func sendHDTransaction(transactionParameters: Parameters, completion: @escaping (_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/transaction/send", method: .post, parameters: transactionParameters, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                } 
            case .failure(_):
                if let data = response.data {
                    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any] {
                        print(json)
                        let bakcError = NSError(domain: "", code: json["code"] as! Int, userInfo: ["Message" : json["message"] as! String])
                        completion(nil, bakcError)
                        break
                    }
                }
                completion(nil, response.result.error)
                break
            }
            
        }
    }

    
    func getWalletOutputs(currencyID: UInt32, address: String, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        let header: HTTPHeaders = [
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/outputs/spendable/\(currencyID)/\(address)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func getCreatedWalletTransactionHistory(currencyID: NSNumber, networkID: NSNumber, walletID: NSNumber, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        let header: HTTPHeaders = [
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/wallets/transactions/\(currencyID)/\(networkID)/\(walletID)/\(WalletType.Created.rawValue)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func getMultisigWalletTransactionHistory(currencyID: NSNumber, networkID: NSNumber, address: String, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        let header: HTTPHeaders = [
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/wallets/transactions/\(currencyID)/\(networkID)/\(address)/\(WalletType.Multisig.rawValue)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func getImportedWalletTransactionHistory(currencyID: NSNumber, networkID: NSNumber, address: String, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        let header: HTTPHeaders = [
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/wallets/transactions/\(currencyID)/\(networkID)/\(address)/\(WalletType.Imported.rawValue)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func changeCreatedWalletName(currencyID: NSNumber, chainType: NSNumber, walletID: NSNumber, newName: String, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        let params = [
            "walletname"    : newName,
            "currencyID"    : currencyID.intValue,
            "walletIndex"   : walletID.intValue,
            "networkID"     : chainType.intValue,
            "type"          : WalletType.Created.rawValue
            ] as [String : Any]
        
        requestManager.request("\(apiUrl)api/v1/wallet/name", method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func changeImportedWalletName(currencyID: NSNumber, chainType: NSNumber, address: String, newName: String, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        let params = [
            "walletname"    : newName,
            "currencyID"    : currencyID.intValue,
            "address"       : address,
            "networkID"     : chainType.intValue,
            "type"          : WalletType.Imported.rawValue
            ] as [String : Any]
        
        requestManager.request("\(apiUrl)api/v1/wallet/name", method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    //MARK: add chain ID
    func getAddressBalance(currencyID: NSNumber, address: String, completion: @escaping(_ answer: NSDictionary?,_ error: Error?) -> ()) {
        let header: HTTPHeaders = [
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/address/balance/\(currencyID)/\(address)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion((response.result.value as! NSDictionary), nil)
                }
            case .failure(_):
                completion(nil, response.result.error)
                break
            }
        }
    }
    
    func estimation(for mustisigAddress: String, completion: @escaping(Result<NSDictionary, String>) -> ()) {
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/multisig/estimate/\(mustisigAddress)", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(_):
                completion(Result.failure(response.result.error!.localizedDescription))
                break
            }
        }
    }
    
    func resyncCreatedWallet(currencyID: NSNumber, chainType: NSNumber, walletID: NSNumber, completion: @escaping(Result<NSDictionary, String>) -> ()) {
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/resync/wallet/\(currencyID)/\(chainType)/\(walletID)/\(WalletType.Created.rawValue)", method: .post, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    print(response.result.value as! NSDictionary)
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(_):
                completion(Result.failure(response.result.error!.localizedDescription))
                break
            }
        }
    }
    
    func resyncImportedWallet(currencyID: NSNumber, chainType: NSNumber, address: String, completion: @escaping(Result<NSDictionary, String>) -> ()) {
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        requestManager.request("\(apiUrl)api/v1/resync/wallet/\(currencyID)/\(chainType)/\(address)/\(WalletType.Imported.rawValue)", method: .post, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    print(response.result.value as! NSDictionary)
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(_):
                completion(Result.failure(response.result.error!.localizedDescription))
                break
            }
        }
    }
    
    func convertToBroken(currencyID: NSNumber, networkID: NSNumber, walletID: NSNumber, completion: @escaping(Result<NSDictionary, String>) -> ()) {
        let header: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        let params : Parameters = [
            "currencyID"    : currencyID,
            "networkID"     : networkID,
            "walletIndex"   : walletID
        ]
        
        requestManager.request("\(apiUrl)api/v1/wallet/convert/imported", method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    print(response.result.value as! NSDictionary)
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(_):
                completion(Result.failure(response.result.error!.localizedDescription))
                break
            }
        }
    }
    
    func convertToBroken(_ addresses: [String], completion: @escaping(Result<NSDictionary, String>) -> ()) {
        let header: HTTPHeaders = [
            "Content-Type"  : "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        
        let params : Parameters = [
            "addresses"    : addresses
        ]
        
        requestManager.request("\(apiUrl)api/v1/wallet/convert/broken", method: .post, parameters: params, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    print(response.result.value as! NSDictionary)
                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(_):
                completion(Result.failure(response.result.error!.localizedDescription))
                break
            }
        }
    }
    
    func getSupportedExchanges(completion: @escaping(Result<[String], String>) -> ()) {
        let header: HTTPHeaders = [
            "Content-Type"  : "application/json",
            "Authorization" : "Bearer \(self.token)"
        ]
        requestManager.request("\(apiUrl)api/v1/exchanger/supported_currencies", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: header).validate().debugLog().responseJSON { (response: DataResponse<Any>) in
            switch response.result {
            case .success(_):
                if response.result.value != nil {
                    print(response.result.value as! NSDictionary)
//                    completion(Result.success(response.result.value as! NSDictionary))
                } else {
                    completion(Result.failure("Error"))
                }
            case .failure(_):
                completion(Result.failure(response.result.error!.localizedDescription))
                break
            }
        }
    }
}

