//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDelegate = WalletViewController
private typealias TableViewDataSource = WalletViewController

class WalletViewController: UIViewController {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var pendingStack: UIStackView!
    @IBOutlet weak var navigationHeaderView: UIView!
    
    // HEADER section
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
    
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var shareAddressBtn: UIButton!
    @IBOutlet weak var showAddressesBtn: UIButton!
    @IBOutlet weak var tablesHeaderView: UIView!
    @IBOutlet weak var backupView: UIView!
    @IBOutlet weak var assetsTransactionsBtnsView: UIView!
    @IBOutlet weak var assetsBtn: UIButton!
    @IBOutlet weak var transactionsBtn: UIButton!
    @IBOutlet weak var underlineView: UIView!
    
    @IBOutlet weak var assetsTable: UITableView!
    @IBOutlet weak var transactionsTable: UITableView!
    @IBOutlet weak var actionsBtnsView: UIView!
    @IBOutlet weak var gradientView: UIView!
    
    // Constraints Section
    @IBOutlet weak var pendingSectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pendingSeparatorWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var backupViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var assetsTansactionsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var assetsTableTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomGradientHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomGradientConstant: NSLayoutConstraint!
    
    var presenter = WalletPresenter()
    
    var isAssets = true
    
    var tablesHeaderStartY = CGFloat()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.walletVC = self
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
    }
    
    override func viewDidLayoutSubviews() {
        tablesHeaderView.roundCorners(corners: [.topLeft, .topRight], radius: 10)
    }
    
    func setupUI() {
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(dragTable))
        if assetsTable.gestureRecognizers?.count == 5 {
            assetsTable.addGestureRecognizer(gestureRecognizer)
            tablesHeaderView.addGestureRecognizer(gestureRecognizer)
//            self.recog = gestureRecognizer
        }
        
        
        checkConstraints()
        makeGradientForBottom()
        setupTransactionAssetsBtns()
        
        //------------  WARNING  ------------//
//        setTransactionsTableFirst()  // if wallet tokens == nil // ONLY TRANSACTIONS
        // ------------  WARNING  ------------
       
//        hideBackup()
        setupAddressBtns()
        
        showHidePendingScetion(show: false)
        
        actionsBtnsView.setShadow(with: #colorLiteral(red: 0, green: 0.2705882353, blue: 0.5607843137, alpha: 0.15))
        assetsTable.contentInset = makeTableInset()
        transactionsTable.contentInset = makeTableInset()
        
        tablesHeaderStartY = tablesHeaderView.frame.origin.y
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
    
    func setupTransactionAssetsBtns() {
        if isAssets {
            transactionsBtn.setTitleColor(#colorLiteral(red: 0.5294117647, green: 0.631372549, blue: 0.7725490196, alpha: 1), for: .normal)
            assetsBtn.setTitleColor(#colorLiteral(red: 0.2117647059, green: 0.2117647059, blue: 0.2117647059, alpha: 1), for: .normal)
            assetsTableTrailingConstraint.constant = 0
            UIView.animate(withDuration: 0.2) {
                self.underlineView.frame.origin.x = 16
                self.view.layoutIfNeeded()
            }
            
        } else {
            transactionsBtn.setTitleColor(#colorLiteral(red: 0.2117647059, green: 0.2117647059, blue: 0.2117647059, alpha: 1), for: .normal)
            assetsBtn.setTitleColor(#colorLiteral(red: 0.5294117647, green: 0.631372549, blue: 0.7725490196, alpha: 1), for: .normal)
            assetsTableTrailingConstraint.constant = -screenWidth
            UIView.animate(withDuration: 0.2) {
                self.underlineView.frame.origin.x = screenWidth - self.underlineView.frame.width - 16
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func setTransactionsTableFirst() {
        hideAssetsBtn()
        assetsTableTrailingConstraint.constant = -screenWidth
        self.view.layoutIfNeeded()
    }
    
    func hideAssetsBtn() {
        assetsTransactionsBtnsView.isHidden = true
        assetsTansactionsHeightConstraint.constant = 0
    }
    
    func hideBackup() {
        backupViewHeightConstraint.constant = 0
        backupView.isHidden = true
    }
    
    func setupAddressBtns() {
        //if blockchain == BLOCKCHAIN_ETHEREUM {
        shareAddressBtn.frame.origin.x = screenWidth/2 - shareAddressBtn.frame.size.width/2
        showAddressesBtn.isHidden = true
        self.view.layoutIfNeeded()
        // else all good
    }
    
    func topOffsetForTable() -> CGFloat {
        if assetsTransactionsBtnsView.isHidden && backupView.isHidden {
            return 0
        } else if assetsTransactionsBtnsView.isHidden == false || backupView.isHidden == false {
            return 16
        }
        return 0
    }
    
    func showHidePendingScetion(show: Bool) {
        if show {
            self.pendingSectionView.isHidden = !show
        }
        pendingSeparatorWidthConstraint.constant = show ? 150 : 0
        pendingSectionHeightConstraint.constant = show ? 70 : 0
        pendingStack.isHidden = !show
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        }) { (isEnd) in
            self.pendingSectionView.isHidden = !show
        }
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
    
    
    
    
    @IBAction func backAction(_ sender: Any) {
        assetsTableTrailingConstraint.constant = 0
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func assetsAction(_ sender: Any) {
        isAssets = true
        setupTransactionAssetsBtns()
    }
    
    @IBAction func transactionsAction(_ sender: Any) {
        isAssets = false
        setupTransactionAssetsBtns()
    }
    
    @IBAction func sendAction(_ sender: Any) {
        showHidePendingScetion(show: false)
    }
    
    @IBAction func receiveAction(_ sender: Any) {
        showHidePendingScetion(show: true)
    }
    
    
}

extension TableViewDelegate: UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    @IBAction func dragTable(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self.view)
        let tablesHeaderY = tablesHeaderView.frame.origin.y
        // check is table on top
        if tablesHeaderY + translation.y < navigationHeaderView.frame.maxY {
            if tablesHeaderY + translation.y > 80 {
                
            } else {
                //setTableToTop()
//                if self.presenter.numberOfTransactions() > 5 {
//                    self.tableView.removeGestureRecognizer(recog!)
            }
        }
        
        
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            if translation.y > 0 && tablesHeaderY > tablesHeaderStartY {
                
                    // show spiner
                    var transY = translation.y > 200 ? translation.y : translation.y/2
                    transY = transY > 270 ? transY : transY/2
                    self.changeTablesHeight(transY: transY)
                    self.changeSectionsY(transY: transY)
                    gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
                
                    
                
            }
        }
    }
    
    func changeTablesHeight(transY: CGFloat) {
        assetsTable.frame.size.height = assetsTable.frame.size.height - transY
        assetsTable.center = CGPoint(x: self.view.center.x, y:assetsTable.center.y + transY)
        
        transactionsTable.frame.size.height = transactionsTable.frame.size.height - transY
        transactionsTable.center = CGPoint(x: self.view.center.x, y:transactionsTable.center.y + transY)
    }
    
    func changeSectionsY(transY: CGFloat) {
        tablesHeaderView.frame.origin.y = tablesHeaderView.frame.origin.y + transY
        backupView.frame.origin.y = tablesHeaderView.frame.maxY
        assetsTransactionsBtnsView.frame.origin.y = backupView.frame.maxY
        
    }
}

extension TableViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showHidePendingScetion(show: true)
    }
}
