//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import ZFRippleButton

private typealias TableViewDelegate = SendDetailsViewController
private typealias TableViewDataSource = SendDetailsViewController
private typealias LocalizeDelegate = SendDetailsViewController

class SendDetailsViewController: UIViewController, UITextFieldDelegate, AnalyticsProtocol {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var viewForShadow: UIView!
    @IBOutlet weak var donationView: UIView!
    @IBOutlet weak var donationSeparatorView: UIView!
    @IBOutlet weak var donationTitleLbl: UILabel!
    @IBOutlet weak var donationTF: UITextField!
    @IBOutlet weak var donationFiatSumLbl: UILabel!
    @IBOutlet weak var donationFiatNameLbl: UILabel!
    @IBOutlet weak var donationCryptoNameLbl: UILabel!
    @IBOutlet weak var isDonateAvailableSW: UISwitch!
    @IBOutlet weak var feeRateDescriptionView: UILabel!
    
    @IBOutlet weak var donationHolderView: UIView!
    @IBOutlet weak var nextBtn: ZFRippleButton!
    
    @IBOutlet weak var bottomBtnConstraint: NSLayoutConstraint!
    @IBOutlet weak var nextButtonTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var donationHolderTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var donationHeightConstraint: NSLayoutConstraint!
    
    
    let presenter = SendDetailsPresenter()
    
    var maxLengthForSum = 12
    
    let loader = PreloaderView(frame: HUDFrame, text: "Updating rates", image: #imageLiteral(resourceName: "walletHuge"))
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.vc = self
        presenter.vcViewDidLoad()
        
        sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)")
        sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: donationEnableTap)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.nextBtn.applyGradient(withColours: [UIColor(ciColor: CIColor(red: 0/255, green: 178/255, blue: 255/255)),
                                                 UIColor(ciColor: CIColor(red: 0/255, green: 122/255, blue: 255/255))],
                                   gradientOrientation: .horizontal)
        
        let firstCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? TransactionFeeTableViewCell
        if firstCell != nil {
            firstCell!.setCornersForFirstCell()
        }
        
        updateConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.vcViewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter.vcViewWillDisappear()
    }
    
    func updateConstraints() {
        if presenter.isDonationAvailable {
            donationHolderTopConstraint.constant = 39
            donationHeightConstraint.constant = presenter.isDonationSwitchedOn! ? 267 : 193
        } else {
            donationHolderTopConstraint.constant = -267
            donationHeightConstraint.constant = 267
        }
        
        let contentHeight = feeRateDescriptionView.frame.maxY + donationHolderTopConstraint.constant + donationHeightConstraint.constant + 25 + nextBtn.frame.height
        let nextButtonContentInBoundTopConstant = (view.frame.size.height - nextBtn.frame.size.height - bottomLayoutGuide.length - topLayoutGuide.length) - (feeRateDescriptionView.frame.maxY + donationHolderTopConstraint.constant + donationHeightConstraint.constant)
        let nextButtonContentOutOfBoundTopConstant : CGFloat = 25 
        nextButtonTopConstraint.constant = contentHeight < view.frame.size.height ? nextButtonContentInBoundTopConstant : nextButtonContentOutOfBoundTopConstant
        view.layoutIfNeeded()
    }
    
    func setupShadow() {
        let myColor = #colorLiteral(red: 0.6509803922, green: 0.6941176471, blue: 0.7764705882, alpha: 0.5)
        viewForShadow.setShadow(with: myColor)
        donationView.setShadow(with: myColor)
    }
    
    func setupUI() {
        view.addSubview(loader)
        tabBarController?.tabBar.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        enableSwipeToBack()
        hideKeyboardWhenTappedAround()
        registerCells()
        setupShadow()
        setupDonationUI()
        
        if presenter.selectedIndexOfSpeed == nil {
            presenter.selectedIndexOfSpeed = 2
            tableView.reloadData()
        }
    }
    
    func setupDonationUI() {
        if presenter.isDonationAvailable {
            donationHolderView.isHidden = false
            presenter.isDonationSwitchedOn = true
            
            self.donationTF.text = presenter.donationInCryptoString ?? BigInt.zero().stringValue
            self.donationFiatSumLbl.text = presenter.donationInFiatString ?? BigInt.zero().stringValue
        } else {
            donationHolderView.isHidden = true
        }
    }
    
    func updateDonationUI() {
        if presenter.isDonationAvailable {
            donationHolderView.isHidden = false
            
            if presenter.isDonationSwitchedOn! {
                donationSeparatorView.isHidden = false
                
                self.donationTF.text = presenter.donationInCryptoString != nil ? presenter.donationInCryptoString! :  BigInt.zero().stringValue
                self.donationFiatSumLbl.text = presenter.donationInFiatString != nil ? presenter.donationInFiatString! : BigInt.zero().stringValue
                
            } else {
                if donationTF.isFirstResponder {
                    donationTF.resignFirstResponder()
                }
            }            
        } else {
            donationHolderView.isHidden = true
        }
        
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard self != nil else {
                return
            }
            
            self!.updateConstraints()
        }) { [weak self] (success) in
            guard self != nil else {
                return
            }
            
            if !self!.presenter.isDonationSwitchedOn! {
                self!.donationSeparatorView.isHidden = true
            }
        }
    }
    
    func registerCells() {
        let transactionCell = UINib(nibName: "TransactionFeeTableViewCell", bundle: nil)
        self.tableView.register(transactionCell, forCellReuseIdentifier: "transactionCell")
        
        let customFeeCell = UINib(nibName: "CustomTrasanctionFeeTableViewCell", bundle: nil)
        self.tableView.register(customFeeCell, forCellReuseIdentifier: "customFeeCell")
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
        sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(presenter.transactionDTO.choosenWallet!.chain)", eventName: closeTap)
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        self.tabBarController?.selectedIndex = 0
        self.navigationController?.popToRootViewController(animated: false)
    }
    
    @IBAction func nextAction(_ sender: Any) {
        self.view.endEditing(true)
        
        if self.presenter.selectedIndexOfSpeed != nil {
            presenter.segueToAmount()
        } else {
            let alert = UIAlertController(title: localize(string: Constants.pleaseChooseFeeRate), message: localize(string: Constants.predefinedValueMessageString), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    //MARK: Keyboard to scrollview
    func addNotificationsObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(SendDetailsViewController.keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SendDetailsViewController.keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func removeNotificationsObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
                if screenHeight == heightOfX {
                    bottomBtnConstraint.constant -= 35
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y != 0{
                self.view.frame.origin.y += keyboardSize.height
                if screenHeight == heightOfX {
                    bottomBtnConstraint.constant = 0
                }
            }
        }
    }
    //end
    
    //MARK: donationSwitch actions
    @IBAction func switchDonationAction(_ sender: Any) {
        presenter.isDonationSwitchedOn = isDonateAvailableSW.isOn
    }

    
    //MARK: TextField delegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.donationTF.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.scrollView.isScrollEnabled = false
        self.scrollView.scrollRectToVisible(self.nextBtn.frame, animated: true)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.scrollView.isScrollEnabled = true
    }
    
    func presentWarning(message: String) {
        let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard var prevAmount = textField.text else { return true }
        
        let changeSymbol = string
        
        if prevAmount == "0" && changeSymbol != "," && changeSymbol != "." && !changeSymbol.isEmpty {
            prevAmount = ""
        } else if prevAmount.isEmpty && (changeSymbol == "," || changeSymbol == ".") {
            return false
        }

        if (changeSymbol == "," || changeSymbol == ".") && prevAmount == "" {
            prevAmount = "0"
        }
        
        if changeSymbol == "" {
            prevAmount.removeLast()
            if prevAmount == "" {
                prevAmount = "0"
            }
        }
        
        let newLength = prevAmount.count + changeSymbol.count - range.length
        
        if newLength <= self.maxLengthForSum {
            var donation = prevAmount + changeSymbol
            
            if (changeSymbol != "," || changeSymbol != ".") && !presenter.isPossibleToDonate(donation) {
                if string != "" {
                    self.presentWarning(message: localize(string: Constants.moreThenYouHaveString))
                    return false
                }
            }
            
            donation = donation.replacingOccurrences(of: ",", with: ".")
            if string == "," && prevAmount.contains(".") {
                return false
            }
            if donation.contains(".") && string != "" {
                let strAfterDot: [String] = donation.components(separatedBy: ".")
                if strAfterDot[1].count >= 8 {
                    return false
                }
            }
            
            presenter.changeDonationString(donation)
        }
        sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: donationChanged)
        
        return false
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "sendAmountVC" {
            let sendAmountVC = segue.destination as! SendAmountViewController
            sendAmountVC.presenter.transactionDTO = presenter.transactionDTO
        }
    }
    
    func updateCellsVisibility () {
        let cells = tableView.visibleCells
        
        guard presenter.selectedIndexOfSpeed != nil && presenter.selectedIndexOfSpeed! < cells.count else {
            return
        }
        
        for cell in cells {
            updateCellVisibility(cell)
        }
    }
    
    func updateCellVisibility(_ cell: UITableViewCell) {
        let index = tableView.indexPathForRow(at: cell.center)?.row
        guard index != nil && presenter.selectedIndexOfSpeed != nil else {
            return
        }
        
        cell.alpha = index! == presenter.selectedIndexOfSpeed! ? 1.0 : 0.3
        if !cell.isKind(of: CustomTrasanctionFeeTableViewCell.self) {
            (cell as! TransactionFeeTableViewCell).checkMarkImage.isHidden = index! != presenter.selectedIndexOfSpeed!
        }
    }
}

extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: veryFastTap)
        case 1:
            sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: fastTap)
        case 2:
            sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: mediumTap)
        case 3:
            sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: slowTap)
        case 4:
            sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: verySlowTap)
        case 5:
            sendAnalyticsEvent(screenName: "\(screenTransactionFeeWithChain)\(self.presenter.transactionDTO.choosenWallet!.chain)", eventName: customTap)
        default : break
        }
        
        presenter.selectedIndexOfSpeed = indexPath.row
        if indexPath.row == 5 {
            let storyboard = UIStoryboard(name: "Send", bundle: nil)
            let customVC = storyboard.instantiateViewController(withIdentifier: "customVC") as! CustomFeeViewController
            customVC.presenter.blockchainType = self.presenter.transactionDTO.choosenWallet!.blockchainType
            customVC.delegate = presenter
            customVC.rate = presenter.customFee != nil ? presenter.customFee! : BigInt.zero()
            customVC.previousSelected = presenter.selectedIndexOfSpeed
            navigationController?.pushViewController(customVC, animated: true)
        } 
    }
}

extension TableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row != 5 {
            let transactionCell = tableView.dequeueReusableCell(withIdentifier: "transactionCell") as! TransactionFeeTableViewCell
            transactionCell.feeRate = presenter.feeRates
            transactionCell.blockchainType = BlockchainType.create(wallet: self.presenter.transactionDTO.choosenWallet!)
            transactionCell.makeCellBy(indexPath: indexPath)
            
            return transactionCell
        } else {
            let customFeeCell = tableView.dequeueReusableCell(withIdentifier: "customFeeCell") as! CustomTrasanctionFeeTableViewCell
            customFeeCell.blockchainType = BlockchainType.create(wallet: self.presenter.transactionDTO.choosenWallet!)
            let fee = presenter.customFee?.stringValue ?? BigInt.zero().stringValue
            customFeeCell.value = UInt64(fee)!
            customFeeCell.setupUI()
            
            return customFeeCell
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        updateCellVisibility(cell)
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Sends"
    }
}
