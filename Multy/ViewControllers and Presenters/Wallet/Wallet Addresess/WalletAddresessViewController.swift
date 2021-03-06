//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Alamofire
//import MultyCoreLibrary

class WalletAddresessViewController: UIViewController,AnalyticsProtocol {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var headerLbl: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    let presenter = WalletAddresessPresenter()
    var whereFrom: UIViewController?
    var addressTransferDelegate: AddressTransferProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.enableSwipeToBack()
        self.presenter.addressesVC = self
        self.registerCell()
        
        self.tableView.tableFooterView = UIView()
        
        if self.whereFrom?.className == WalletSettingsViewController.className {
            self.addButton.isHidden = true
        }
        
        let blocchainType = BlockchainType.create(wallet: presenter.wallet!)
        if blocchainType.blockchain != BLOCKCHAIN_BITCOIN {
            addButton.isHidden = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateExchange), name: NSNotification.Name("exchageUpdated"), object: nil)
        sendAnalyticsEvent(screenName: "\(screenWalletAddressWithChain)\(presenter.wallet!.chain)", eventName: "\(screenWalletAddressWithChain)\(presenter.wallet!.chain)")
    }
    
    func registerCell() {
        let addressCell = UINib(nibName: "WalletAddressTableViewCell", bundle: nil)
        self.tableView.register(addressCell, forCellReuseIdentifier: "addressCell")
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        sendAnalyticsEvent(screenName: "\(screenWalletAddressWithChain)\(presenter.wallet!.chain)", eventName: "\(closeWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func addAdress(_ sender: Any) {
        addAddress()
    }
    
    
    @objc func updateExchange() {
        let cells = self.tableView.visibleCells
        for cell in cells {
            let addressCell = cell as! WalletAddressTableViewCell
            addressCell.updateExchange()
        }
    }
    
}

extension WalletAddresessViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.presenter.numberOfAddress()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let addressCell = self.tableView.dequeueReusableCell(withIdentifier: "addressCell") as! WalletAddressTableViewCell
        addressCell.wallet = self.presenter.wallet
        addressCell.fillInCell(index: indexPath.row)
        
        return addressCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return (64.0 / 375.0) * screenWidth
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        if self.whereFrom == nil {
            let adressVC = storyboard.instantiateViewController(withIdentifier: "walletAdressVC") as! AddressViewController
            adressVC.modalPresentationStyle = .overCurrentContext
            adressVC.addressIndex = indexPath.row
            adressVC.wallet = self.presenter.wallet
            //        self.mainVC.present
            self.present(adressVC, animated: true, completion: nil)
            sendAnalyticsEvent(screenName: "\(screenWalletAddressWithChain)\(presenter.wallet!.chain)", eventName: "\(addressWithChainTap)\(presenter.wallet!.chain)")
        } else {
            if whereFrom?.className == ReceiveAllDetailsViewController.className {
                self.addressTransferDelegate?.transfer(newAddress: self.presenter.wallet!.addresses[indexPath.row].address)
                self.navigationController?.popViewController(animated: true)
                return
            }
            presentPrivateKeyView(wallet: presenter.wallet!, addressIndex: indexPath.row)
        }
        self.tableView.deselectRow(at: indexPath, animated: true)

        sendAnalyticsEvent(screenName: "\(screenWalletAddressWithChain)\(presenter.wallet!.chain)", eventName: "\(addressWithChainTap)\(presenter.wallet!.chain)")
        
        //FIXME: adding adresses to wallet//remove
//        addAddress()
    }
    
    func addAddress() {
        var params : Parameters = [ : ]
        
        let dm = DataManager.shared
        dm.getAccount { [unowned self, unowned dm] (account, error) in
            if error != nil {
                return
            }
            
            var binaryData = account!.binaryDataString.createBinaryData()!
            
            let data = dm.coreLibManager.createAddress(blockchainType: BlockchainType.create(wallet: self.presenter.wallet!),
                                                                       walletID: self.presenter.wallet!.walletID.uint32Value,
                                                                       addressID: UInt32(self.presenter.wallet!.addresses.count),
                                                                       binaryData: &binaryData)
            
            params["walletIndex"] = self.presenter.wallet!.walletID
            params["address"] = data!["address"] as! String
            params["addressIndex"] = self.presenter.wallet!.addresses.count
            params["networkID"] = self.presenter.wallet!.chainType
            params["currencyID"] = self.presenter.wallet!.chain
            
            dm.addAddress(params: params) { [unowned self, unowned dm] (dict, error) in
                dm.getOneWalletVerbose(wallet: self.presenter.wallet!, completion: { [unowned self] (wallet, error) in
                                                        self.presenter.wallet = wallet
                                                        self.tableView.reloadData()
                })
            }
        }
    }
}
