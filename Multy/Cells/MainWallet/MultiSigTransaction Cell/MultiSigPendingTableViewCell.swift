//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details


// 124 row height with one bottom view

import UIKit

class MultiSigPendingTableViewCell: UITableViewCell {

    @IBOutlet weak var transactionImg: UIImageView!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var cryptoSumLbl: UILabel!
    @IBOutlet weak var cryptoNameLbl: UILabel!
    @IBOutlet weak var fiatSumLbl: UILabel!
    @IBOutlet weak var fiatNameLbl: UILabel!
    @IBOutlet weak var additionalInfoLbl: UILabel!
    
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
    @IBOutlet weak var declineViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var watchViewWidthConstraint: NSLayoutConstraint!
    
    
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
        let cryptoAmountString = BigInt(histObj.txOutAmountString).cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
        let fiatAmountString = (BigInt(histObj.txOutAmountString) * histObj.fiatCourseExchange).fiatValueString(for: BLOCKCHAIN_ETHEREUM)
        if cryptoAmountString != "" {  // if empty need to hide view
            lockedCryptoLbl.text = cryptoAmountString + " " + wallet!.cryptoName
            lockedFiatLbl.text = fiatAmountString + " " + wallet!.fiatName
        } else {
            heightOfBigViewConstraint.constant = 48
        }
        
        cryptoSumLbl.text = cryptoAmountString
        fiatSumLbl.text = fiatAmountString
    }
}
