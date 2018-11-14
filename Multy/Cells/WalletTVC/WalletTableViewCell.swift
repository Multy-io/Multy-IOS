//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

private typealias LocalizeDelegate = WalletTableViewCell

class WalletTableViewCell: UITableViewCell {

    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var tokenImage: UIImageView!
    @IBOutlet weak var walletNameLbl: UILabel!
    @IBOutlet weak var cryptoSumLbl: UILabel!
    @IBOutlet weak var cryptoNameLbl: UILabel!
    @IBOutlet weak var fiatSumLbl: UILabel!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var statusImage: UIImageView!
    
    @IBOutlet weak var resyncingStatusLabel: UILabel!
    @IBOutlet weak var msStatusLbl: UILabel!
    @IBOutlet weak var nameYConstraint: NSLayoutConstraint!
    @IBOutlet weak var backViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectedView: UIView!
    
    var isBorderOn = false
    var isCellSelected = false
    var wallet: UserWalletRLM?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        setupShadow(false)
//        self.backView.layer.shadowColor = UIColor.black.cgColor
//        self.backView.layer.shadowOpacity = 0.1
//        self.backView.layer.shadowOffset = .zero
//        self.backView.layer.shadowRadius = 2
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setupShadow(_ selected : Bool) {
        backView.layer.shadowColor = #colorLiteral(red: 0.6509803922, green: 0.6941176471, blue: 0.7764705882, alpha: 0.6).cgColor
        backView.layer.shadowOpacity = selected ? 0 : 0.7
        backView.layer.shadowOffset = selected ? .zero : CGSize(width: 0, height: 2)
        backView.layer.shadowRadius = selected ? 6 : 3
    }
    
//    func makeshadow() {
//        self.backView.dropShadow(color: #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), opacity: 1.0, offSet: CGSize(width: -1, height: 1), radius: 4, scale: true)
//    }
    
    func makeBlueBorderAndArrow() {
        self.backView.layer.borderWidth = 2
        self.backView.layer.borderColor = #colorLiteral(red: 0, green: 0.4823529412, blue: 1, alpha: 1)
        self.arrowImage.image = #imageLiteral(resourceName: "checkmark")
        self.isBorderOn = true
    }
    
    func clearBorderAndArrow() {
        UIView.animate(withDuration: 1.0, delay: 0.0, options:[.repeat, .autoreverse], animations: {
            self.backView.layer.borderColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        }, completion:nil)
        
        self.backView.layer.borderWidth = 0
        self.arrowImage.image = nil
        self.isBorderOn = false
    }
    
    func fillInCell() {
        let blockchainType = BlockchainType.createAssociated(wallet: wallet!)
        tokenImage.image = UIImage(named: blockchainType.iconString)
        walletNameLbl.text = makeWalletName()
        walletNameLbl.textColor = blockchainType.colorForWalletName
        cryptoNameLbl.text = blockchainType.shortName
        fiatSumLbl.text = wallet!.sumInFiatString + " " + self.wallet!.fiatSymbol
        
        cryptoSumLbl.text = wallet?.sumInCryptoString

        setupStatusImage()
        notDeployedMsSetup(isMS: wallet!.isMultiSig, isMsDeployed: wallet?.multisigWallet?.isDeployed)
    }
    
    func makeWalletName() -> String {
        var walletName = String()
        if wallet!.isMultiSig == true {
            let countOfMembers = wallet!.multisigWallet!.ownersCount
            let signsCount = wallet!.multisigWallet!.signaturesRequiredCount
            walletName = "\(wallet!.name)" + " ∙ " + "\(signsCount) \(localize(string: Constants.ofString)) \(countOfMembers)"
        } else {
            walletName = wallet!.name
        }
        
        return walletName
    }
    
    func setupStatusImage() {
        switch wallet!.isMultiSig {
        case true:
            if wallet!.multisigWallet!.deployStatus.intValue == DeployStatus.pending.rawValue {
                statusImage.image = UIImage(named: "pending")
                statusImage.isHidden = false
            } else if wallet!.multisigWallet!.isActivePaymentRequest {
                statusImage.image = UIImage(named: "arrowWaiting")
                statusImage.isHidden = false
            } else {
                statusImage.isHidden = true
            }
        case false:
            if wallet!.isTherePendingTx.boolValue {
                statusImage.image = UIImage(named: "pending")
                statusImage.isHidden = false
            } else if wallet!.isSyncing.boolValue {
                statusImage.image = UIImage(named: "resyncing")
                statusImage.isHidden = false
            } else {
                statusImage.isHidden = true
            }
        }
    }
    
    func notDeployedMsSetup(isMS: Bool, isMsDeployed: Bool?) {
        if isMS && isMsDeployed != nil {
            if isMsDeployed! == false && wallet?.chainType == 1 {
                tokenImage.image = tokenImage.image
            } else {
                tokenImage.image = isMsDeployed! ? tokenImage.image : UIImage(named: "ethMSMediumIconGrey")
            }
            cryptoSumLbl.isHidden = !isMsDeployed!
            fiatSumLbl.isHidden = !isMsDeployed!
            cryptoNameLbl.isHidden = !isMsDeployed!
            msStatusLbl.isHidden = isMsDeployed!
            nameYConstraint.constant = isMsDeployed! ? 0 : -15
            msStatusLbl.text = isMsDeployed! ? "" : makeMSStatusText()
        } else {
            cryptoSumLbl.isHidden = false
            fiatSumLbl.isHidden = false
            cryptoNameLbl.isHidden = false
            msStatusLbl.isHidden = true
            nameYConstraint.constant = 0
        }
    }
    
    func makeMSStatusText() -> String {
        let msDeployStatus = wallet!.multisigWallet!.deployStatus.intValue
        if msDeployStatus == DeployStatus.created.rawValue {
            return "Not all members connected..."
        } else if msDeployStatus == DeployStatus.ready.rawValue {
            return "Ready to start. Payment needed..."
        } else { //if msDeployStatus == DeployStatus.pending.rawValue {
            return "Payment pending..."
        }
    }
    
    func selectCell(_ selected: Bool) {
        selectedView.backgroundColor = selected ? #colorLiteral(red: 0.5294117647, green: 0.631372549, blue: 0.7725490196, alpha: 0.2988816353) : #colorLiteral(red: 0.9254901961, green: 0.9333333333, blue: 0.968627451, alpha: 1)
        contentView.layoutIfNeeded()
        setupShadow(selected)
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Wallets"
    }
}
