//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import ZFRippleButton

private typealias LocalizeDelegate = ReceiveStartViewController

class ReceiveStartViewController: UIViewController, AnalyticsProtocol {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleLbl: UILabel!
    
    let presenter = ReceiveStartPresenter()
    
    weak var sendWalletDelegate: SendWalletProtocol?
    
    var titleTextKey = Constants.receiveString
    
    var whereFrom: UIViewController?
    
    let loader = PreloaderView(frame: HUDFrame, text: "", image: #imageLiteral(resourceName: "walletHuge"))
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(loader)
        self.swipeToBack()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.tabBar.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        self.titleLbl.text = localize(string: titleTextKey)
        
        self.presenter.receiveStartVC = self
        self.registerCells()
//        self.presenter.createWallets()
        if presenter.walletsArr.count == 0 {
            self.presenter.getWallets()
        }
        sendAnalyticsEvent(screenName: screenReceive, eventName: screenReceive)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.tabBarController as! CustomTabBarViewController).menuButton.isHidden = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
//            self.deselectCell()
//        })
    }
    
    func registerCells() {
        let walletCell = UINib.init(nibName: "WalletTableViewCell", bundle: nil)
        self.tableView.register(walletCell, forCellReuseIdentifier: "walletCell")
        
        let newWalletCell = UINib.init(nibName: "NewExchangeWalletTableViewCell", bundle: nil)
        self.tableView.register(newWalletCell, forCellReuseIdentifier: "newWalletCell")
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        if self.presenter.isNeedToPop {
            self.navigationController?.popViewController(animated: true)
        } else {
            if let tbc = self.tabBarController as? CustomTabBarViewController {
                tbc.setSelectIndex(from: 2, to: tbc.previousSelectedIndex)
            }
            self.navigationController?.popToRootViewController(animated: false)
        }
        sendAnalyticsEvent(screenName: screenReceive, eventName: closeTap)
    }

//    Deselecting
//    
//    func deselectCell() {
//        if self.presenter.selectedIndexPath != nil {
//            let walletCell = self.tableView.cellForRow(at: self.presenter.selectedIndexPath!) as! WalletTableViewCell
//            walletCell.clearBorderAndArrow()
//        }
//    }
    
}

extension ReceiveStartViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if whereFrom?.className == CurrencyToExchangeViewController.className {
            return self.presenter.numberOfWallets() + 1
        } else {
            return self.presenter.numberOfWallets()
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row >= presenter.numberOfWallets() {
            let newWalletCell = self.tableView.dequeueReusableCell(withIdentifier: "newWalletCell") as! NewExchangeWalletTableViewCell
            newWalletCell.setGradient()
            return newWalletCell
        } else {
            let walletCell = self.tableView.dequeueReusableCell(withIdentifier: "walletCell") as! WalletTableViewCell
            walletCell.arrowImage.image = nil
            walletCell.wallet = self.presenter.walletsArr[indexPath.row]
            walletCell.fillInCell()
            
            return walletCell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.presenter.selectedIndex = indexPath.row
        if self.presenter.isNeedToPop == true {
            if self.whereFrom?.className == CurrencyToExchangeViewController.className {
                //delegate to send wallet
                if indexPath.row >= presenter.numberOfWallets() {
                    sendWalletDelegate?.sendWallet(wallet: DataManager.shared.createTempWallet(blockchainType: presenter.walletsArr[indexPath.row - 1].blockchainType))
                } else {
                    sendWalletDelegate?.sendWallet(wallet: presenter.walletsArr[indexPath.row])
                }
                navigationController?.popToViewController(navigationController!.childViewControllers[2], animated: true)
            } else if self.whereFrom != nil && self.presenter.walletsArr[indexPath.row].availableAmount.isZero {
                let message = localize(string: Constants.cannotChooseEmptyWalletString)
                let alert = UIAlertController(title: localize(string: Constants.sorryString), message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                shakeView(viewForShake: self.tableView.cellForRow(at: indexPath)!)
            } else {
                self.sendWalletDelegate?.sendWallet(wallet: self.presenter.walletsArr[self.presenter.selectedIndex!])
                self.navigationController?.popViewController(animated: true)
            }
        } else {
            self.performSegue(withIdentifier: "receiveDetails", sender: Any.self)
        }
        if indexPath.row >= presenter.numberOfWallets() {
            //creating temp wallet
        } else {
            sendAnalyticsEvent(screenName: screenReceive, eventName: "\(walletWithChainTap)\(presenter.walletsArr[indexPath.row].chain)")
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 104
    }
    

    
    func updateUI() {
        self.tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "receiveDetails" {
            let receiveDetails = segue.destination as! ReceiveAllDetailsViewController
            receiveDetails.presenter.wallet = self.presenter.walletsArr[self.presenter.selectedIndex!]
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Receives"
    }
}
