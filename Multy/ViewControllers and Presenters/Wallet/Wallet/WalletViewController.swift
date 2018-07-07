//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDelegate = WalletViewController
private typealias TableViewDataSource = WalletViewController
private typealias AnimationSection = WalletViewController
private typealias LocalizeDelegate = WalletViewController
private typealias CancelDelegate = WalletViewController
private typealias ScrollViewDelegate = WalletViewController

class WalletViewController: UIViewController, AnalyticsProtocol {

    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var pendingStack: UIStackView!
    @IBOutlet weak var navigationHeaderView: UIView!
    @IBOutlet weak var spiner: UIActivityIndicatorView!
    
    // HEADER section
    @IBOutlet weak var availableSectionView: UIView!
    @IBOutlet weak var amountCryptoLbl: UILabel!
    @IBOutlet weak var nameCryptoLbl: UILabel!
    @IBOutlet weak var fiatAmountLbl: UILabel!
        //Pening
    @IBOutlet weak var pendingSectionView: UIView!
    
    @IBOutlet weak var pendingAmountCryptoLbl: UILabel!
    @IBOutlet weak var pendingNameCryptoLbl: UILabel!
    @IBOutlet weak var pendingAmountFiatLbl: UILabel!
        //
    //
    
    @IBOutlet weak var adressWithBtnView: UIView!
    @IBOutlet weak var addressButtonsStackView: UIStackView!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var shareAddressBtn: UIButton!
    @IBOutlet weak var showAddressesBtn: UIButton!
    @IBOutlet weak var backupView: UIView!
    @IBOutlet weak var assetsTransactionsBtnsView: UIView!
    @IBOutlet weak var assetsBtn: UIButton!
    @IBOutlet weak var transactionsBtn: UIButton!
    @IBOutlet weak var underlineView: UIView!
    
    @IBOutlet weak var assetsTable: UITableView!
    @IBOutlet weak var transactionsTable: UITableView!
    
    @IBOutlet weak var emptyLbl: UILabel!
    @IBOutlet weak var emptyArrowImg: UIImageView!
    
    @IBOutlet weak var actionsBtnsView: UIView!
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var infoHolderView: UIView!
    
    // Constraints Section
    @IBOutlet weak var pendingSectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pendingSeparatorWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var assetsTansactionsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var assetsTableTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomGradientHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var assetsTransactionsTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var underlineViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableHolderViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomGradientConstant: NSLayoutConstraint!
    
    var presenter = WalletPresenter()
    
    //FIXME: set true when add assets functionality
    var isAssets = false
    
    var visibleCells = 5
    
    var isCanUpdate = true {
        didSet {
            if isCanUpdate == true && tableHolderViewHeight < tablesHolderBottomEdge {
                setTableHolderPosition()
            }
        }
    }
    
    var isViewDidAppear = false
    
    var tablesHolderTopEdge: CGFloat {
        return contentHeight - (navigationHeaderView.frame.origin.y + navigationHeaderView.frame.size.height)
    }
    
    var tablesHolderBottomEdge: CGFloat = 0 {
        didSet {
            if oldValue != tablesHolderBottomEdge {
                tableHolderViewHeight = tablesHolderBottomEdge
            }
        }
    }
    
    var tablesHolderFlipEdge: CGFloat {
        return contentHeight - (infoHolderView.frame.origin.y + infoHolderView.frame.size.height / 2 )
    }
    
    var contentHeight : CGFloat {
        return self.contentView.frame.size.height
    }
    
    var tableHolderViewHeight : CGFloat = 0 {
        didSet {
            if oldValue != tableHolderViewHeight {
                var infoHolderTopSpace : CGFloat = 0
                if tableHolderViewHeight < tablesHolderBottomEdge {
                    infoHolderTopSpace = tablesHolderBottomEdge - tableHolderViewHeight
                }
                infoHolderTopConstraint.constant = infoHolderTopSpace
                if infoHolderTopSpace >= 40 {
                    if !spiner.isAnimating {
                        spiner.startAnimating()
                    }
                } else {
                    if spiner.isAnimating {
                        spiner.stopAnimating()
                    }
                }
 
                tableHolderViewHeightConstraint.constant = tableHolderViewHeight
                self.view.layoutIfNeeded()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.walletVC = self
        presenter.registerCells()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.getHistoryAndWallet()
        presenter.updateUI()
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateExchange), name: NSNotification.Name("exchageUpdated"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateWalletAfterSockets), name: NSNotification.Name("transactionUpdated"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        isViewDidAppear = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !isViewDidAppear {
            setupUI()
        }
    }
    
    @objc func updateExchange() {
        presenter.updateUI()
    }
    
    func setupUI() {
        checkConstraints()
        makeGradientForBottom()
        setupTransactionAssetsBtns(false)
        
        //------------  WARNING  ------------//
        setTransactionsTableFirst()  // if wallet tokens == nil // ONLY TRANSACTIONS
        // ------------  WARNING  ------------
       
        setupAddressBtns()
        
        showHidePendingSection(false)
        
        checkForBackup()
        
        actionsBtnsView.setShadow(with: #colorLiteral(red: 0, green: 0.2705882353, blue: 0.5607843137, alpha: 0.15))
        assetsTable.contentInset = makeTableInset()
        transactionsTable.contentInset = makeTableInset()
        tablesHolderBottomEdge = contentHeight - (infoHolderView.frame.origin.y + infoHolderView.frame.size.height)
    }
    
    func checkConstraints() {
        if screenHeight == heightOfX {
            bottomGradientConstant.constant = -34
            bottomGradientHeightConstraint.constant = 100
            self.view.layoutIfNeeded()
        }
    }
    
    func makeGradientForBottom() {
        let colorTop = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.8).cgColor
        let colorBottom = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.0).cgColor
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [colorBottom, colorTop]
        gradientLayer.locations = [0.0, 0.4]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: screenWidth, height: bottomGradientHeightConstraint.constant)
        gradientView.layer.addSublayer(gradientLayer)
    }
    
    func setupTransactionAssetsBtns(_ animated: Bool) {
        if isAssets {
            transactionsBtn.setTitleColor(#colorLiteral(red: 0.5294117647, green: 0.631372549, blue: 0.7725490196, alpha: 1), for: .normal)
            assetsBtn.setTitleColor(#colorLiteral(red: 0.2117647059, green: 0.2117647059, blue: 0.2117647059, alpha: 1), for: .normal)
            assetsTableTrailingConstraint.constant = 0
            underlineViewLeadingConstraint.constant = (assetsBtn.frame.size.width - underlineView.frame.size.width) / 2
        } else {
            transactionsBtn.setTitleColor(#colorLiteral(red: 0.2117647059, green: 0.2117647059, blue: 0.2117647059, alpha: 1), for: .normal)
            assetsBtn.setTitleColor(#colorLiteral(red: 0.5294117647, green: 0.631372549, blue: 0.7725490196, alpha: 1), for: .normal)
            assetsTableTrailingConstraint.constant = -screenWidth
            underlineViewLeadingConstraint.constant = assetsBtn.frame.size.width + (transactionsBtn.frame.size.width - underlineView.frame.size.width) / 2
        }
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
        }
    }
    
    func setTransactionsTableFirst() {
        hideAssetsBtn()
        assetsTableTrailingConstraint.constant = -screenWidth
        view.layoutIfNeeded()
    }
    
    func hideAssetsBtn() {
        assetsTransactionsBtnsView.isHidden = true
        assetsTansactionsHeightConstraint.constant = 0
    }
    
    func hideBackup() {
        assetsTransactionsTopConstraint.constant = 20
        backupView.isHidden = true
    }
    
    func setupAddressBtns() {
        if presenter.wallet!.blockchain == BLOCKCHAIN_ETHEREUM {
            addressButtonsStackView.removeArrangedSubview(showAddressesBtn)
            showAddressesBtn.isHidden = true
        }
    }
    
    func checkForBackup() {
        if self.presenter.account!.isSeedPhraseSaved() {
            hideBackup()
        }
    }
    
    func topOffsetForTable() -> CGFloat {
        if assetsTransactionsBtnsView.isHidden && backupView.isHidden {
            return 0
        } else if assetsTransactionsBtnsView.isHidden == false || backupView.isHidden == false {
            return 16
        }
        return 0
    }
    
    func showHidePendingSection(_ animated: Bool) {
        let isNeedToShow = presenter.wallet!.isThereBlockedAmount
        
        if isNeedToShow {
            pendingSectionView.isHidden = !isNeedToShow
        }
        pendingSeparatorWidthConstraint.constant = isNeedToShow ? 150 : 0
        pendingSectionHeightConstraint.constant = isNeedToShow ? 70 : 0
        pendingStack.isHidden = !isNeedToShow
        
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
            }) { (isEnd) in
                self.pendingSectionView.isHidden = !isNeedToShow
            }
        } else {
            self.pendingSectionView.isHidden = !isNeedToShow
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func updateWalletAfterSockets() {
        if presenter.isSocketInitiateUpdating {
            return
        }
        
        if !isVisible() {
            return
        }
        
        presenter.isSocketInitiateUpdating = true
        presenter.getHistoryAndWallet()
    }
    
    func makeTableInset() -> UIEdgeInsets {
        var topInset = CGFloat()
        if assetsTransactionsBtnsView.isHidden && backupView.isHidden {
            topInset = 0
        } else if assetsTransactionsBtnsView.isHidden == false || backupView.isHidden == false {
            topInset = 16
        }
        
        return UIEdgeInsets(top: topInset, left: 0, bottom: bottomGradientHeightConstraint.constant, right: 0)
    }
    
    func setTableHolderPosition() {
        var tableHolderViewHeight = self.tableHolderViewHeight
        if tableHolderViewHeight < tablesHolderBottomEdge {
            tableHolderViewHeight = tablesHolderBottomEdge
        } else {
            if tableHolderViewHeight > tablesHolderFlipEdge {
                tableHolderViewHeight = tablesHolderTopEdge
            } else {
                tableHolderViewHeight = tablesHolderBottomEdge
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.tableHolderViewHeight = tableHolderViewHeight
        }
    }
    
    func setInitialTableHolderPosition() {
        let tableView = isAssets ? assetsTable : transactionsTable
        tableView?.setContentOffset(CGPoint.zero, animated: false)
        UIView.animate(withDuration: 0.3, animations: {
            self.tableHolderViewHeight = self.tablesHolderBottomEdge
            
        }) { (succeeded) in
            
        }
    }
    
    func updateWalletsAfterDragging() {
        UIView.animate(withDuration: 0.3) {
            self.tableHolderViewHeight = self.tablesHolderBottomEdge - 40
        }
        
        presenter.getHistoryAndWallet()
    }
    
    @IBAction func titleAction(_ sender: Any) {
        if tableHolderViewHeight == tablesHolderTopEdge {
            setInitialTableHolderPosition()
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        assetsTableTrailingConstraint.constant = 0
//        self.navigationController?.popViewController(animated: true)
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func shareAddressAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let adressVC = storyboard.instantiateViewController(withIdentifier: "walletAdressVC") as! AddressViewController
        adressVC.modalPresentationStyle = .overCurrentContext
        adressVC.modalTransitionStyle = .crossDissolve
//        adressVC.wallet = self.wallet
        //        self.mainVC.present
        present(adressVC, animated: true, completion: nil)
//        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(wallet!.chain)", eventName: "\(addressWithChainTap)\(wallet!.chain)")
    }
    
    @IBAction func showAllAddressesAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let adressesVC = storyboard.instantiateViewController(withIdentifier: "walletAddresses") as! WalletAddresessViewController
//        adressesVC.presenter.wallet = self.wallet
        navigationController?.pushViewController(adressesVC, animated: true)
//        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(wallet!.chain)", eventName: "\(allAddressesWithChainTap)\(wallet!.chain)")
    }
    
    @IBAction func backupAction(_ sender: Any) {
        let stroryboard = UIStoryboard(name: "SeedPhrase", bundle: nil)
        let vc = stroryboard.instantiateViewController(withIdentifier: "seedAbout")
        navigationController?.pushViewController(vc, animated: true)
//        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet!.chain)", eventName: backupSeedTap)
    }
    
    @IBAction func assetsAction(_ sender: Any) {
        isAssets = true
        setupTransactionAssetsBtns(true)
    }
    
    @IBAction func transactionsAction(_ sender: Any) {
        isAssets = false
        setupTransactionAssetsBtns(true)
    }

    @IBAction func sendAction(_ sender: Any) {
        if presenter.wallet!.availableAmount.isZero {
            self.presentAlert(with: localize(string: Constants.noFundsString))
            
            return
        }
        
        let storyboard = UIStoryboard(name: "Send", bundle: nil)
        let sendStartVC = storyboard.instantiateViewController(withIdentifier: "sendStart") as! SendStartViewController
        sendStartVC.presenter.transactionDTO.choosenWallet = self.presenter.wallet
        sendStartVC.presenter.isFromWallet = true
        self.navigationController?.pushViewController(sendStartVC, animated: true)
        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet!.chain)", eventName: "\(sendWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func receiveAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Receive", bundle: nil)
        let receiveDetailsVC = storyboard.instantiateViewController(withIdentifier: "receiveDetails") as! ReceiveAllDetailsViewController
        receiveDetailsVC.presenter.wallet = self.presenter.wallet
        self.navigationController?.pushViewController(receiveDetailsVC, animated: true)
        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet!.chain)", eventName: "\(receiveWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func settingssAction(_ sender: Any) {
        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet!.chain)", eventName: "\(settingsWithChainTap)\(presenter.wallet!.chain)")
        self.performSegue(withIdentifier: "settingsVC", sender: sender)
    }
    
    @IBAction func showAddressAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let adressVC = storyboard.instantiateViewController(withIdentifier: "walletAdressVC") as! AddressViewController
        adressVC.modalPresentationStyle = .overCurrentContext
        adressVC.modalTransitionStyle = .crossDissolve
        adressVC.wallet = presenter.wallet
        present(adressVC, animated: true, completion: nil)
        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet!.chain)", eventName: "\(addressWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func showAllAddressessAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let adressesVC = storyboard.instantiateViewController(withIdentifier: "walletAddresses") as! WalletAddresessViewController
        adressesVC.presenter.wallet = presenter.wallet
        navigationController?.pushViewController(adressesVC, animated: true)
        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet!.chain)", eventName: "\(allAddressesWithChainTap)\(presenter.wallet!.chain)")
    }
    
    @IBAction func exchangeAction(_ sender: Any) {
        unowned let weakSelf =  self
        self.presentDonationAlertVC(from: weakSelf, with: "io.multy.addingExchange50")
        //        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet!.chain)", eventName: "\(exchangeWithChainTap)\(presenter.wallet!.chain)")
        logAnalytics()
    }
    
    func logAnalytics() {
        sendDonationAlertScreenPresentedAnalytics(code: donationForExchangeFUNC)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "settingsVC" {
            let settingsVC = segue.destination as! WalletSettingsViewController
            settingsVC.presenter.wallet = self.presenter.wallet
        }
    }
}

extension TableViewDelegate: UITableViewDelegate {
    //FIXME: hideEmptyLbls
    func hideEmptyLbls() {
        emptyLbl.isHidden = true
        emptyArrowImg.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == transactionsTable {
            if tableView.numberOfRows(inSection: 0) == 0 {
                return
            }
            let countOfHistObjs = presenter.transactionDataSource.count
            if indexPath.row >= countOfHistObjs && countOfHistObjs <= visibleCells {
                return
            }
            
            let storyBoard = UIStoryboard(name: "Wallet", bundle: nil)
            let transactionVC = storyBoard.instantiateViewController(withIdentifier: "transaction") as! TransactionViewController
            transactionVC.presenter.histObj = presenter.transactionDataSource[indexPath.row]
            transactionVC.presenter.blockchainType = BlockchainType.create(wallet: presenter.wallet!)
            transactionVC.presenter.wallet = presenter.wallet!
            self.navigationController?.pushViewController(transactionVC, animated: true)
            sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet!.chain)", eventName: "\(transactionWithChainTap)\(presenter.wallet!.chain)")
        } else {
            
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == transactionsTable {
            if indexPath.row < presenter.transactionDataSource.count && presenter.isTherePendingMoney(for: indexPath) {
                return 135
            } else {
                return 80
            }
        } else {
            return 80
        }
    }
}

extension TableViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let countOfHistObjs = presenter.transactionDataSource.count
        
        if tableView == transactionsTable {
            if indexPath.row < countOfHistObjs && presenter.isTherePendingMoney(for: indexPath) {
                let pendingTrasactionCell = tableView.dequeueReusableCell(withIdentifier: "TransactionPendingCellID") as! TransactionPendingCell
                pendingTrasactionCell.selectionStyle = .none
                pendingTrasactionCell.histObj = presenter.transactionDataSource[indexPath.row]
                pendingTrasactionCell.wallet = presenter.wallet
                pendingTrasactionCell.fillCell()
                
                return pendingTrasactionCell
            } else {
                let transactionCell = transactionsTable.dequeueReusableCell(withIdentifier: "TransactionWalletCellID") as! TransactionWalletCell
                transactionCell.selectionStyle = .none
                if countOfHistObjs > 0 {
                    if indexPath.row >= countOfHistObjs {
                        transactionCell.changeState(isEmpty: true)
                    } else {
                        transactionCell.histObj = presenter.transactionDataSource[indexPath.row]
                        transactionCell.wallet = presenter.wallet!
                        transactionCell.fillCell()
                        transactionCell.changeState(isEmpty: false)
                        hideEmptyLbls()                    }
                } else {
                    transactionCell.changeState(isEmpty: true)
                    //                    fixForiPad()
                }
                
                return transactionCell
            }
        } else {
            let transactionCell = transactionsTable.dequeueReusableCell(withIdentifier: "TransactionWalletCellID") as! TransactionWalletCell
            
            return transactionCell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == transactionsTable {
            let countOfHistObjects = presenter.transactionDataSource.count
            if countOfHistObjects > 0 {
                tableView.isScrollEnabled = true
                if countOfHistObjects < 10 {
                    return 10
                } else {
                    return countOfHistObjects
                }
            } else {
                if screenHeight == heightOfX {
                    return 13
                }
                return 10
            }
        } else {
            return 10
        }
    }
}

extension CancelDelegate : CancelProtocol {
    func cancelAction() {
        makePurchaseFor(productId: "io.multy.addingExchange5")
    }
    
    func donate50(idOfProduct: String) {
        makePurchaseFor(productId: idOfProduct)
    }
    
    func presentNoInternet() {
        
    }
}

extension ScrollViewDelegate: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var tableHolderViewHeight = self.tableHolderViewHeight
        
        if tableHolderViewHeight < tablesHolderTopEdge {
            if tableHolderViewHeight < tablesHolderBottomEdge {
                if scrollView.contentOffset.y < 0 {
                    tableHolderViewHeight += scrollView.contentOffset.y / 3
                } else {
                    tableHolderViewHeight += scrollView.contentOffset.y
                }
            } else {
                tableHolderViewHeight += scrollView.contentOffset.y
                tableHolderViewHeight = tableHolderViewHeight > tablesHolderTopEdge ? tablesHolderTopEdge : tableHolderViewHeight
            }
            
            if scrollView.contentOffset.y > 0 {
                scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
            }
            
            self.tableHolderViewHeight = tableHolderViewHeight
        } else {
            if scrollView.contentOffset.y < 0 {
                tableHolderViewHeight += scrollView.contentOffset.y
                self.tableHolderViewHeight = tableHolderViewHeight
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if tableHolderViewHeight < tablesHolderBottomEdge - 40 {
            updateWalletsAfterDragging()
        } else {
            setTableHolderPosition()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setTableHolderPosition()
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Wallets"
    }
}
