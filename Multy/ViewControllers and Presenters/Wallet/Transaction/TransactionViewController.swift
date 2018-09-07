//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = TransactionViewController
private typealias PickerContactsDelegate = TransactionViewController
private typealias AnalyticsDelegate = TransactionViewController
private typealias MultisigDelegate = TransactionViewController
private typealias CancelDelegate = TransactionViewController

class TransactionViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var backImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var transactionImg: UIImageView!
    @IBOutlet weak var transctionSumLbl: UILabel! // +0.0152 receive | -0.0123 send
    @IBOutlet weak var transactionCurencyLbl: UILabel! // BTC | ETH
    @IBOutlet weak var sumInFiatLbl: UILabel! //+1 174 USD receive | -1 123 EUR send
    @IBOutlet weak var noteLbl: UILabel!
    @IBOutlet weak var walletFromAddressLbl: UILabel!
    @IBOutlet weak var arrowImg: UIImageView!  // downArrow receive | upArrow send
    @IBOutlet weak var blockchainImg: UIImageView!
    @IBOutlet weak var personNameLbl: UILabel!   // To Vadim
    @IBOutlet weak var walletToAddressLbl: UILabel!
    @IBOutlet weak var numberOfConfirmationLbl: UILabel! // 6 Confirmations
    @IBOutlet weak var viewInBlockchainBtn: UIButton!
    @IBOutlet weak var constraintNoteFiatSum: NSLayoutConstraint! // set 20 if note == ""
    @IBOutlet weak var blockchainInfoView: UIView!
    @IBOutlet weak var transactionInfoHolderView: UIView!
    @IBOutlet weak var spiner: UIActivityIndicatorView!
    
    @IBOutlet weak var donationView: UIView!
    @IBOutlet weak var donationCryptoSum: UILabel!
    @IBOutlet weak var donationCryptoName: UILabel!
    @IBOutlet weak var donationFiatSumAndName: UILabel!
    @IBOutlet weak var constraintDonationHeight: NSLayoutConstraint!
    @IBOutlet weak var blockchainInfoViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollContentHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var doubleSliderHolderViewHeight: NSLayoutConstraint!
    
    
    // MultiSig outlets
    @IBOutlet weak var confirmationDetailsHolderView: UIView!
    @IBOutlet weak var confirmationAmountLbl: UILabel!
    @IBOutlet weak var confirmationMembersCollectionView: UICollectionView!
    @IBOutlet weak var confirmaitionDetailsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var doubleSliderHolderView: UIView!
    @IBOutlet weak var noBalanceErrorHolderView: UIView!
    @IBOutlet weak var noBalanceAddress: UILabel!
    @IBOutlet weak var copiedView: UIView!
    
    let presenter = TransactionPresenter()
    
    var isForReceive = true
    var cryptoName = "BTC"
    
    var sumInCripto = 1.125
    var fiatSum = 1255.23
    var fiatName = "USD"
    
    var isIncoming = true
    
    var isMultisig = false 
    
    var isDecided : Bool {
        get {
            var result = false
            let confirmationStatus = presenter.wallet.confirmationStatusForTransaction(transaction: presenter.histObj)
            if confirmationStatus == ConfirmationStatus.confirmed || confirmationStatus == ConfirmationStatus.declined {
                result = true
            }
            return result
        }
    }
    
    var state = 0
    
    var doubleSliderVC : DoubleSlideViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.swipeToBack()
        self.presenter.transctionVC = self
        configureCollectionViews()
        self.tabBarController?.tabBar.isHidden = true
        self.tabBarController?.tabBar.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        self.isIncoming = presenter.histObj.isIncoming()
        self.checkMultisig()
        self.checkHeightForScrollAvailability()
        self.checkStatus()
        self.constraintDonationHeight.constant = 0
        self.donationView.isHidden = true
        self.sendAnalyticOnStrart()
        
        
        let tapOnTo = UITapGestureRecognizer(target: self, action: #selector(tapOnToAddress))
        walletToAddressLbl.isUserInteractionEnabled = true
        walletToAddressLbl.addGestureRecognizer(tapOnTo)
        
        let tapOnFrom = UITapGestureRecognizer(target: self, action: #selector(tapOnFromAddress))
        walletFromAddressLbl.isUserInteractionEnabled = true
        walletFromAddressLbl.addGestureRecognizer(tapOnFrom)
        
        self.scrollView.isScrollEnabled = true
        
        presenter.createPreliminaryData()
        presenter.requestFee()
        
        if isMultisig && !presenter.isMultisigTxViewed {
            presenter.viewMultisigTx()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        
        if isMultisig {
            let sendStoryboard = UIStoryboard(name: "Send", bundle: nil)
            doubleSliderVC = sendStoryboard.instantiateViewController(withIdentifier: "doubleSlideView") as! DoubleSlideViewController
            doubleSliderVC.delegate = self
            add(doubleSliderVC, to: doubleSliderHolderView)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.updateMultisigWalletAfterSockets(notification:)), name: NSNotification.Name("msTransactionUpdated"), object: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMultisig {
            NotificationCenter.default.removeObserver(self)
            doubleSliderVC.remove()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        updateBottomConstraints()
    }
    
    func updateBottomConstraints() {
        scrollContentHeightConstraint.constant = contentHeight()
        self.view.layoutIfNeeded()
    }
    
    func configureCollectionViews() {
        let confirmationStatusNib = UINib(nibName: "ConfirmationStatusCollectionViewCell", bundle: nil)
        confirmationMembersCollectionView.register(confirmationStatusNib, forCellWithReuseIdentifier: "ConfirmationStatusCVCReuseId")
    }
    
    @objc func tapOnToAddress(recog: UITapGestureRecognizer) {
        tapFunction(recog: recog, labelFor: walletToAddressLbl)
    }
    
    @objc func tapOnFromAddress(recog: UITapGestureRecognizer) {
        tapFunction(recog: recog, labelFor: walletFromAddressLbl)
    }

    func tapFunction(recog: UITapGestureRecognizer, labelFor: UILabel) {
        let tapLocation = recog.location(in: labelFor)
        var lineNumber = Double(tapLocation.y / 16.5)
        lineNumber.round(.towardZero)
        var title = ""
        title = copyAdressFor(labelFor: labelFor, lineNumber: Int(lineNumber))
        
        let actionSheet = UIAlertController(title: "", message: title, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: localize(string: Constants.cancelString), style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: localize(string: Constants.copyToClipboardString), style: .default, handler: { (action) in
            UIPasteboard.general.string = title
        }))
        
        if DataManager.shared.isAddressSaved(title) == false {
            actionSheet.addAction(UIAlertAction(title: localize(string: Constants.addToContacts), style: .default, handler: { [unowned self] (action) in
                self.presenter.selectedAddress = title
                self.presentiPhoneContacts()
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: localize(string: Constants.shareString), style: .default, handler: { (action) in
            let objectsToShare = [title]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            activityVC.completionWithItemsHandler = {(activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
                if !completed {
                    // User canceled
                    return
                } else {
                    if let appName = activityType?.rawValue {
                        //                        self.sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(self.wallet!.chain)", eventName: "\(shareToAppWithChainTap)\(self.wallet!.chain)_\(appName)")
                    }
                }
            }
            activityVC.setPresentedShareDialogToDelegate()
            self.present(activityVC, animated: true, completion: nil)
        }))
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func copyAdressFor(labelFor: UILabel, lineNumber: Int) -> String {
        switch self.presenter.wallet.blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            if labelFor == walletFromAddressLbl {
                return presenter.histObj.txInputs[Int(lineNumber)].address
            } else { // if walletToAddressLbl
                return presenter.histObj.txOutputs[Int(lineNumber)].address
            }
        default:    //case BLOCKCHAIN_ETHEREUM
            if labelFor == walletFromAddressLbl {
                return presenter.histObj.addressesArray.first!
            } else { // if walletToAddressLbl
                return presenter.histObj.addressesArray.last!
            }
        }
    }
    
    func checkHeightForScrollAvailability() {
//        if screenHeight >= 667 {
//            self.scrollView.isScrollEnabled = false
//        }
    }
    
    func checkStatus() {
        if isMultisig && presenter.histObj.multisig != nil  {
            if presenter.histObj.multisig!.confirmed.boolValue {
                if isIncoming {  // RECEIVE
                    self.makeBackColor(color: self.presenter.receiveBackColor)
                    self.titleLbl.text = localize(string: Constants.transactionInfoString)
                } else {                        // SEND
                    self.makeBackColor(color: self.presenter.sendBackColor)
                    self.titleLbl.text = localize(string: Constants.transactionInfoString)
                    self.transactionImg.image = #imageLiteral(resourceName: "sendBigIcon")
                }
                self.titleLbl.textColor = .white
                backImageView.image = UIImage(named: "backWhite")
            } else {
                // Multisig transaction waiting confirmation
                self.makeBackColor(color: self.presenter.waitingConfirmationBackColor)
                self.titleLbl.text = "Transaction details"
                self.titleLbl.textColor = .black
                self.transactionImg.image = #imageLiteral(resourceName: "waitingMembersBigIcon")
            }
            
        } else {
            if isIncoming {  // RECEIVE
                self.makeBackColor(color: self.presenter.receiveBackColor)
                self.titleLbl.text = localize(string: Constants.transactionInfoString)
            } else {                        // SEND
                self.makeBackColor(color: self.presenter.sendBackColor)
                self.titleLbl.text = localize(string: Constants.transactionInfoString)
                self.transactionImg.image = #imageLiteral(resourceName: "sendBigIcon")
            }
            self.titleLbl.textColor = .white
            backImageView.image = UIImage(named: "backWhite")
        }
        self.updateUI()
    }
    
    func checkMultisig() {
        isMultisig = presenter.histObj.multisig != nil
        confirmationDetailsHolderView.isHidden = !isMultisig
        doubleSliderHolderView.isHidden = !isMultisig
    }
    
    func contentHeight() -> CGFloat {
        var result = transactionInfoHolderView.frame.origin.y + transactionInfoHolderView.frame.size.height + 16
        if isMultisig {
            confirmaitionDetailsHeightConstraint.constant = confirmationMembersCollectionView.contentSize.height + 50
            result = result + confirmaitionDetailsHeightConstraint.constant + 16
            
            if !isDecided {
                result += doubleSliderHolderView.frame.size.height
            }
        } else if presenter.isDonationExist {
            result = result + 300
        }
        
        return result
    }
    
    func updateUI() {
        //        BTC
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm, d MMMM yyyy"
        let cryptoSumInBTC = UInt64(truncating: presenter.histObj.txOutAmount).btcValue
        
        if isMultisig {
            if presenter.histObj.multisig!.confirmed.boolValue {
                if presenter.histObj.txStatus.intValue == TxStatus.MempoolIncoming.rawValue ||
                    presenter.histObj.txStatus.intValue == TxStatus.MempoolOutcoming.rawValue {
                    self.dateLbl.text = dateFormatter.string(from: presenter.histObj.mempoolTime)
                } else {
                    self.dateLbl.text = dateFormatter.string(from: presenter.histObj.blockTime)
                }
                
                self.blockchainInfoView.isHidden = false
                self.blockchainInfoViewHeightConstraint.constant = 104
                self.numberOfConfirmationLbl.text = makeConfirmationText()
                
                doubleSliderHolderView.isHidden = true
                doubleSliderHolderViewHeight.constant = 0
            } else {
                self.dateLbl.text = "Waiting for confirmations..."
                
                self.blockchainInfoView.isHidden = true
                self.blockchainInfoViewHeightConstraint.constant = 8
                
                if isDecided {
                    doubleSliderHolderView.isHidden = true
                    doubleSliderHolderViewHeight.constant = 0
                } else {
                    doubleSliderHolderView.isHidden = false
                    doubleSliderHolderViewHeight.constant = 64
                }
            }
            
            let requiedSignsCount = presenter.wallet.multisigWallet?.signaturesRequiredCount
            let confirmationsCount = presenter.histObj.multisig?.confirmationsCount()
            confirmationAmountLbl.text = "\(confirmationsCount!) of \(requiedSignsCount!)"
            
        } else {
            if presenter.histObj.txStatus.intValue == TxStatus.MempoolIncoming.rawValue ||
                presenter.histObj.txStatus.intValue == TxStatus.MempoolOutcoming.rawValue {
                self.dateLbl.text = dateFormatter.string(from: presenter.histObj.mempoolTime)
            } else {
                self.dateLbl.text = dateFormatter.string(from: presenter.histObj.blockTime)
            }
            
            self.blockchainInfoView.isHidden = false
            self.blockchainInfoViewHeightConstraint.constant = 104
            self.numberOfConfirmationLbl.text = makeConfirmationText()
        }
        
        self.noteLbl.text = "" // NOTE FROM HIST OBJ
        self.constraintNoteFiatSum.constant = 10
        self.personNameLbl.text = "" // before we don`t have address book    OR    Wallet Name
        self.blockchainImg.image = UIImage(named: presenter.blockchainType.iconString)
        
        switch self.presenter.wallet.blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            let arrOfInputsAddresses = presenter.histObj.txInputs.map{ $0.address }.joined(separator: "\n")   // top address lbl
            //        self.transactionCurencyLbl.text = presenter.histObj.     // check currencyID
            self.walletFromAddressLbl.text = arrOfInputsAddresses
            let arrOfOutputsAddresses = presenter.histObj.txOutputs.map{ $0.address }.joined(separator: "\n")
            self.walletToAddressLbl.text = arrOfOutputsAddresses
            
            if isIncoming {
                self.transctionSumLbl.text = "+\(cryptoSumInBTC.fixedFraction(digits: 8))"
                self.sumInFiatLbl.text = "+\((cryptoSumInBTC * presenter.histObj.fiatCourseExchange).fixedFraction(digits: 2)) USD"
            } else {
                let outgoingAmount = presenter.wallet.outgoingAmount(for: presenter.histObj).btcValue
                self.transctionSumLbl.text = "-\(outgoingAmount.fixedFraction(digits: 8))"
                self.sumInFiatLbl.text = "-\((outgoingAmount * presenter.histObj.fiatCourseExchange).fixedFraction(digits: 2)) USD"
                
                if let donationAddress = arrOfOutputsAddresses.getDonationAddress(blockchainType: presenter.blockchainType) {
                    let donatOutPutObj = presenter.histObj.getDonationTxOutput(address: donationAddress)
                    if donatOutPutObj == nil {
                        return
                    }
                    
                    presenter.isDonationExist = true
                    let btcDonation = (donatOutPutObj?.amount as! UInt64).btcValue
                    self.donationView.isHidden = false
                    self.constraintDonationHeight.constant = makeDonationConstraint()
                    self.donationCryptoSum.text = btcDonation.fixedFraction(digits: 8)
                    self.donationCryptoName.text = " BTC"
                    self.donationFiatSumAndName.text = "\((btcDonation * presenter.histObj.fiatCourseExchange).fixedFraction(digits: 2)) USD"
                    
                    updateBottomConstraints()
                }
            }
        case BLOCKCHAIN_ETHEREUM:
            self.transactionCurencyLbl.text = "ETH"     // check currencyID
            self.walletFromAddressLbl.text = presenter.histObj.addressesArray.first
            self.walletToAddressLbl.text = presenter.histObj.addressesArray.last
            
            
            if isIncoming {
                let fiatAmountInWei = BigInt(presenter.histObj.txOutAmountString) * presenter.histObj.fiatCourseExchange
                self.transctionSumLbl.text = "+" + BigInt(presenter.histObj.txOutAmountString).cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
                self.sumInFiatLbl.text = "+" + fiatAmountInWei.fiatValueString(for: BLOCKCHAIN_ETHEREUM) + " USD"
            } else {
                let fiatAmountInWei = BigInt(presenter.histObj.txOutAmountString) * presenter.histObj.fiatCourseExchange
                self.transctionSumLbl.text = "-" + BigInt(presenter.histObj.txOutAmountString).cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
                self.sumInFiatLbl.text = "-" + fiatAmountInWei.fiatValueString(for: BLOCKCHAIN_ETHEREUM) + " USD"
            }
        default: break
        }
        self.confirmationMembersCollectionView.reloadData()
        self.view.layoutIfNeeded()
    }
    
    @objc func updateMultisigWalletAfterSockets(notification : NSNotification) {
        
        if !isVisible() {
            return
        }
        
        guard notification.userInfo != nil else {
            return
        }
        
        let address = notification.userInfo!["To"] as? String
        
        guard address != nil else {
            return
        }
        
        if presenter.wallet.isAddressBelongsToWallet(address!) {
            presenter.updateTx()
        }
    }
    
    func makeDonationConstraint() -> CGFloat {
        var const: CGFloat = 0
        switch screenHeight {
        case heightOfFive: const = 323
        default: const = 283
        }
        return const
    }
    
    func makeBackColor(color: UIColor) {
        self.backView.backgroundColor = color
        self.scrollView.backgroundColor = color
    }
    
    @IBAction func closeAction() {
        self.navigationController?.popViewController(animated: true)
        let blockchainTypeUInt32 = presenter.blockchainType.blockchain.rawValue
        sendAnalyticsEvent(screenName: "\(screenTransactionWithChain)\(blockchainTypeUInt32)", eventName: "\(closeWithChainTap)\(blockchainTypeUInt32)")
    }
    
    @IBAction func viewInBlockchainAction(_ sender: Any) {
        self.performSegue(withIdentifier: "viewInBlockchain", sender: nil)
        let blockchainTypeUInt32 = presenter.blockchainType.blockchain.rawValue
        sendAnalyticsEvent(screenName: "\(screenTransactionWithChain)\(blockchainTypeUInt32)", eventName: "\(viewInBlockchainWithTxStatus)\(blockchainTypeUInt32)_\(state)")
    }
    
    func makeConfirmationText() -> String {
        var textForConfirmations = ""
        switch presenter.histObj.confirmations {
        case 1:
            textForConfirmations = "1 \(localize(string: Constants.confirmationString))"
        default: // not 1
            textForConfirmations = "\(presenter.histObj.confirmations) \(localize(string: Constants.confirmationsString))"
        }
        
        return textForConfirmations
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "viewInBlockchain" {
            let blockchainVC = segue.destination as! ViewInBlockchainViewController
            blockchainVC.presenter.txId = presenter.histObj.txId
            blockchainVC.presenter.blockchainType = presenter.blockchainType
            blockchainVC.presenter.blockchain = presenter.blockchain
            blockchainVC.presenter.txHash = presenter.histObj.txHash
        }
    }
    
    func presentTransactionErrorAlert() {
        let message = localize(string: Constants.errorSendingTxString)
        let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func showNoBalanceView() {
        noBalanceErrorHolderView.isHidden = false
    }
    
    @IBAction func copyNoBalanceAddressAction(_ sender: Any) {
        UIPasteboard.general.string = noBalanceAddress.text
        UIView.animate(withDuration: 0.5, animations: {
            self.copiedView.frame.origin.y = screenHeight - 40
        }) { (isEnd) in
            Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.hideView), userInfo: nil, repeats: false)
        }
        
    }
    
    @objc func hideView() {
        UIView.animate(withDuration: 1, animations: {
            self.copiedView.frame.origin.y = screenHeight + 40
        })
    }
    
    @IBAction func receiveToNoBalanceAddressAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Receive", bundle: nil)
        let receiveDetailsVC = storyboard.instantiateViewController(withIdentifier: "receiveDetails") as! ReceiveAllDetailsViewController
        receiveDetailsVC.presenter.wallet = self.presenter.wallet
        self.navigationController?.pushViewController(receiveDetailsVC, animated: true)
        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(presenter.wallet.chain)", eventName: "\(receiveWithChainTap)\(presenter.wallet.chain)")
    }
    
    @IBAction func exchangeAction(_ sender: Any) {
        unowned let weakSelf =  self
        self.presentDonationAlertVC(from: weakSelf, with: "io.multy.addingExchange50")
        sendDonationAlertScreenPresentedAnalytics(code: donationForExchangeFUNC)
    }
}

extension PickerContactsDelegate: EPPickerDelegate, ContactsProtocol {
    func epContactPicker(_: EPContactsPicker, didSelectContact contact: EPContact) {
        if contact.contactId == nil {
            return
        }
        
        let address = presenter.selectedAddress
        let currencyID = presenter.wallet.chain.uint32Value
        let networkID = presenter.wallet.chainType.uint32Value
        
        updateContactInfo(contact.contactId!, withAddress: address, currencyID, networkID) { [unowned self] _ in
            DispatchQueue.main.async {
                self.updateUI()
                self.logAddedAddressAnalytics()
            }
        }
    }
}

extension AnalyticsDelegate: AnalyticsProtocol {
    func sendAnalyticOnStrart() {
        if self.presenter.blockedAmount(for: presenter.histObj) > 0 {
            state = 0
        } else {
            if isIncoming {
                state = -1
            } else {
                state = 1
            }
        }
        sendAnalyticsEvent(screenName: "\(screenTransactionWithChain)\(presenter.blockchainType.blockchain.rawValue)", eventName: "\(screenTransactionWithChain)\(presenter.blockchainType.blockchain.rawValue)_\(state)")
    }
    
    func logAddedAddressAnalytics() {
        sendAnalyticsEvent(screenName: transactionInfoScreen, eventName: addressAdded)
    }
}

extension MultisigDelegate: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, DoubleSliderDelegate {
    
    //MARK: UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var result = 0
        if isMultisig {
            result = presenter.histObj.multisig!.owners.count
        }
        return result
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ConfirmationStatusCVCReuseId", for: indexPath) as! ConfirmationStatusCollectionViewCell
        let currentOwner = presenter.wallet.currentTransactionOwner(transaction: presenter.histObj)
        if currentOwner != nil {
            let owner = presenter.histObj.multisig!.owners[indexPath.item]
            let confirmationStatus = ConfirmationStatus(rawValue: owner.confirmationStatus.intValue)!
            var date : Date?
            switch confirmationStatus {
            case .waiting:
                break
            case .viewed:
                date = Date(timeIntervalSince1970: owner.viewTime.doubleValue)
            case .confirmed, .declined:
                date = Date(timeIntervalSince1970: owner.confirmationTime.doubleValue)
            }
            
            let name = currentOwner!.address == owner.address ? "You" : nil
            cell.fill(address: owner.address, status: confirmationStatus, memberName: name, date: date)
        }
        
        return cell
    }
    
    //MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: confirmationMembersCollectionView.frame.size.width, height: 64)
    }
    
    //MARK: Slider actions
    func didSlideToSend(_ sender: DoubleSlideViewController) {
        //FIXME: stub
        print("Slide to Send")
        presenter.confirmMultisigTx()
    }
    
    func didSlideToDecline(_ sender: DoubleSlideViewController) {
        //FIXME: stub
        print("Slide to Decline")
        presenter.declineMultisigTx()
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Wallets"
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
