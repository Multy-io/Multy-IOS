//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = TransactionViewController
private typealias PickerContactsDelegate = TransactionViewController
private typealias AnalyticsDelegate = TransactionViewController
private typealias MultisigDelegate = TransactionViewController

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
    
    @IBOutlet weak var donationView: UIView!
    @IBOutlet weak var donationCryptoSum: UILabel!
    @IBOutlet weak var donationCryptoName: UILabel!
    @IBOutlet weak var donationFiatSumAndName: UILabel!
    @IBOutlet weak var constraintDonationHeight: NSLayoutConstraint!
    @IBOutlet weak var blockchainInfoViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollContentHeightConstraint: NSLayoutConstraint!
    
    
    // MultiSig outlets
    @IBOutlet weak var confirmationDetailsHolderView: UIView!
    @IBOutlet weak var confirmationAmount: UILabel!
    @IBOutlet weak var confirmationMembersCollectionView: UICollectionView!
    @IBOutlet weak var confirmaitionDetailsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var doubleSliderHolderView: UIView!
    
    let presenter = TransactionPresenter()
    
    var isForReceive = true
    var cryptoName = "BTC"
    
    var sumInCripto = 1.125
    var fiatSum = 1255.23
    var fiatName = "USD"
    
    var isIncoming = true
    
    var isMultisig = false 
    
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
        self.updateUI()
        self.sendAnalyticOnStrart()
        
        
        let tapOnTo = UITapGestureRecognizer(target: self, action: #selector(tapOnToAddress))
        walletToAddressLbl.isUserInteractionEnabled = true
        walletToAddressLbl.addGestureRecognizer(tapOnTo)
        
        let tapOnFrom = UITapGestureRecognizer(target: self, action: #selector(tapOnFromAddress))
        walletFromAddressLbl.isUserInteractionEnabled = true
        walletFromAddressLbl.addGestureRecognizer(tapOnFrom)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        
        if isMultisig {
            let sendStoryboard = UIStoryboard(name: "Send", bundle: nil)
            doubleSliderVC = sendStoryboard.instantiateViewController(withIdentifier: "doubleSlideView") as! DoubleSlideViewController
            doubleSliderVC.delegate = self
            add(doubleSliderVC, to: doubleSliderHolderView)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMultisig {
            doubleSliderVC.remove()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
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
        if isMultisig && presenter.histObj.isWaitingConfirmation.boolValue {
            // Multisig transaction waiting confirmation
            self.makeBackColor(color: self.presenter.waitingConfirmationBackColor)
            self.titleLbl.text = "Transaction details"
            self.titleLbl.textColor = .black
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
        
    }
    
    func checkMultisig() {
        isMultisig = presenter.histObj.isMultisigTx.boolValue
        confirmationDetailsHolderView.isHidden = !isMultisig
        doubleSliderHolderView.isHidden = !isMultisig
    }
    
    func contentHeight() -> CGFloat {
        var result = transactionInfoHolderView.frame.origin.y + transactionInfoHolderView.frame.size.height + 16
        if isMultisig {
            confirmaitionDetailsHeightConstraint.constant = confirmationMembersCollectionView.contentSize.height + 50
            result = result + confirmaitionDetailsHeightConstraint.constant + 16
            
            if presenter.histObj.isWaitingConfirmation.boolValue {
                result += doubleSliderHolderView.frame.size.height
            }
        }
        return result
    }
    
    func updateUI() {
        //        BTC
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm, d MMMM yyyy"
        let cryptoSumInBTC = UInt64(truncating: presenter.histObj.txOutAmount).btcValue
        
        if isMultisig && presenter.histObj.isWaitingConfirmation.boolValue {
            self.dateLbl.text = "Waiting for confirmations..."
            
            self.blockchainInfoView.isHidden = true
            self.blockchainInfoViewHeightConstraint.constant = 8
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
                    let btcDonation = (donatOutPutObj?.amount as! UInt64).btcValue
                    self.donationView.isHidden = false
                    self.constraintDonationHeight.constant = makeDonationConstraint()
                    self.donationCryptoSum.text = btcDonation.fixedFraction(digits: 8)
                    self.donationCryptoName.text = " BTC"
                    self.donationFiatSumAndName.text = "\((btcDonation * presenter.histObj.fiatCourseExchange).fixedFraction(digits: 2)) USD"
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
        
        self.view.layoutIfNeeded()
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
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ConfirmationStatusCVCReuseId", for: indexPath) as! ConfirmationStatusCollectionViewCell
        switch indexPath.item {
        case 0:
            cell.fill(address: "1KaNqVt2aUPY5Yyh6XiM6gn2KqC8zbGE63", status: .confirmed, memberName: "Zigmund", date: Date(timeIntervalSinceNow: -360))
            break
            
        case 1:
            cell.fill(address: "1LAjEP52mMaJWSRC6g5wdF8wwNFbzCkiRo", status: .waiting, memberName: "Alfredo", date: nil)
            break
            
        case 2:
            cell.fill(address: "13buGNTTQ6dGyAMXJofBRNTgCQPccApMLz", status: .declined, memberName: nil, date: Date(timeIntervalSinceNow: -360))
            break
            
        case 3:
            cell.fill(address: "1DYvmjLcMHuVWHwePyrW6DAAcKwMBbW9j1", status: .viewed, memberName: nil, date: Date(timeIntervalSinceNow: -360))
            break
            
        default:
            break
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
    }
    
    func didSlideToDecline(_ sender: DoubleSlideViewController) {
        //FIXME: stub
        print("Slide to Decline")
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Wallets"
    }
}
