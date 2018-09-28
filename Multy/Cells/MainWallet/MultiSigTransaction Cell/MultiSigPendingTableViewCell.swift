//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details


// 124 row height with one bottom view

import UIKit

private typealias LocalizeDelegate = MultiSigPendingTableViewCell

class MultiSigPendingTableViewCell: UITableViewCell {

    @IBOutlet weak var transactionImg: UIImageView!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var cryptoSumLbl: UILabel!
    @IBOutlet weak var cryptoNameLbl: UILabel!
    @IBOutlet weak var fiatSumLbl: UILabel!
    @IBOutlet weak var fiatNameLbl: UILabel!
    @IBOutlet weak var additionalInfoLbl: UILabel!
    @IBOutlet weak var spaceBetweenTimeConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var infoBlockView: UIView!
    @IBOutlet weak var heightOfBigViewConstraint: NSLayoutConstraint! //normal is 94
    @IBOutlet weak var lockedView: UIView!
    @IBOutlet weak var lockedCryptoLbl: UILabel! //with name at the end
    @IBOutlet weak var lockedFiatLbl: UILabel!
    
    @IBOutlet weak var separatorView: UIView!
    
    @IBOutlet weak var infoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var infoLbl: UILabel!
    @IBOutlet weak var successView: UIView!
    @IBOutlet weak var successApproveCountLbl: UILabel!
    @IBOutlet weak var declineView: UIView!
    @IBOutlet weak var declineApproveCountLbl: UILabel!
    @IBOutlet weak var watchView: UIView!
    @IBOutlet weak var watchApproveCountLbl: UILabel!
    
    @IBOutlet weak var successViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var declineViewWidthConstraint: NSLayoutConstraint! // normal is 46
    @IBOutlet weak var watchViewWidthConstraint: NSLayoutConstraint!   // normal is 46
    
    
    var wallet : UserWalletRLM?
    var histObj = HistoryRLM()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    public func fillCell() {
        fillAddressAndName()
        fillEthereumCell()
        
        makeConfirmationView()
    }
    
    func setupCell() {
//        watchViewWidthConstraint.constant = 0
//        watchView.isHidden = true
        declineViewWidthConstraint.constant = 0
        declineView.isHidden = true
        
        layoutIfNeeded()
    }
    
    func showOnlyLocked() {
        infoHeightConstraint.constant = 0
        lockedView.isHidden = false
        separatorView.isHidden = true
        infoView.isHidden = true
        heightOfBigViewConstraint.constant = 46
    }
    
    func showOnlyInfo() {
        lockedView.isHidden = true
        separatorView.isHidden = true
        heightOfBigViewConstraint.constant = 46
    }
    
    func infoBlock(isNeedToHide: Bool) {
        infoBlockView.isHidden = isNeedToHide
        spaceBetweenTimeConstraint.constant = isNeedToHide ? 3 : 0
    }
    
    func fillAddressAndName() {
//        var savedAddresses = DataManager.shared.savedAddresses
        var address = String()
        
        address = histObj.addressesArray.last!
        
//        if let name = savedAddresses[address] {
//            nameLabel.text = name
//        } else {
//            nameLabel.text = ""
//        }
        addressLbl.text = address
    }
    
    func fillEthereumCell() {
        showOnlyInfo()
//        infoBlock(isNeedToHide: histObj.multisig!.confirmed.boolValue)
        if wallet!.isRejected(tx: histObj) || histObj.txStatus.intValue == TxStatus.RejectedIncoming.rawValue || histObj.txStatus.intValue == TxStatus.RejectedOutgoing.rawValue  {
            transactionImg.image = #imageLiteral(resourceName: "arrowDeclined")
            additionalInfoLbl.text = localize(string: Constants.rejectedString)
        } else if histObj.multisig?.confirmed == false {
            //check for your or not your confirmation
            transactionImg.image = #imageLiteral(resourceName: "arrowWaiting")
            if wallet!.multisigWallet!.signaturesRequiredCount == histObj.multisig!.confirmationsCount() {
//            if histObj.multisig!.isNeedOnlyYourConfirmation(walletAddress: wallet!.address) {
                additionalInfoLbl.text = localize(string: Constants.sendingString)
//                additionalInfoLbl.textColor = #colorLiteral(red: 0.9215686275, green: 0.07843137255, blue: 0.231372549, alpha: 1)
            } else {
                additionalInfoLbl.text = localize(string: Constants.waitingConfirmationsString)
                additionalInfoLbl.textColor = #colorLiteral(red: 0.5294117647, green: 0.631372549, blue: 0.7725490196, alpha: 1)
            }
        } else if histObj.multisig?.confirmed == true {
            let dateFormatter = Date.defaultGMTDateFormatter()
            transactionImg.image = #imageLiteral(resourceName: "arrowSended")
            additionalInfoLbl.text = dateFormatter.string(from: histObj.blockTime)
        }
        
        let cryptoAmount = wallet!.txAmount(histObj)
        let cryptoAmountString = cryptoAmount.cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
        let fiatAmountString = (cryptoAmount * histObj.fiatCourseExchange).fiatValueString(for: BLOCKCHAIN_ETHEREUM)
        if cryptoAmountString != "" {  // if empty need to hide view
            lockedCryptoLbl.text = cryptoAmountString + " " + wallet!.cryptoName
            lockedFiatLbl.text = fiatAmountString + " " + wallet!.fiatName
        } else {
            heightOfBigViewConstraint.constant = 48
        }
        
        cryptoSumLbl.text = cryptoAmountString
        fiatSumLbl.text = fiatAmountString
    }
    
    func makeConfirmationView() {
        let countOfOwners = histObj.multisig?.owners.count
        var countOfConfirmations = 0
        var countOfDecline = 0
        var countOfSeen = 0
        
        for owner in histObj.multisig!.owners {
            if owner.confirmationStatus.intValue == MultisigOwnerTxStatus.msOwnerStatusConfirmed.rawValue {
                countOfConfirmations += 1
            } else if owner.confirmationStatus.intValue == MultisigOwnerTxStatus.msOwnerStatusSeen.rawValue {
                countOfSeen += 1
            } else if owner.confirmationStatus.intValue == MultisigOwnerTxStatus.msOwnerStatusDeclined.rawValue {
                countOfDecline += 1
            }
        }
        
        infoLbl.text = "\(countOfConfirmations)" + " " + localize(string: Constants.ofString) + " " + "\(wallet!.multisigWallet!.signaturesRequiredCount)" + " " + localize(string: Constants.confirmationsString)
        
        if countOfConfirmations > 0 {
            successApproveCountLbl.text = "\(countOfConfirmations)"
            successViewWidthConstraint.constant = 46
            successView.isHidden = false
        } else {
            successViewWidthConstraint.constant = 0
            successView.isHidden = true
        }
        
        if countOfDecline > 0 {
            declineApproveCountLbl.text = "\(countOfDecline)"
            declineViewWidthConstraint.constant = 46
            declineView.isHidden = false
        } else {
            declineViewWidthConstraint.constant = 0
            declineView.isHidden = true
        }
        
        if countOfSeen > 0 {
            watchApproveCountLbl.text = "\(countOfSeen)"
            watchViewWidthConstraint.constant = 46
            watchView.isHidden = false
        } else {
            watchViewWidthConstraint.constant = 0
            watchView.isHidden = true
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "MultiSig"
    }
}

