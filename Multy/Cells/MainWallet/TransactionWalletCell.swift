//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import MultyCoreLibrary

private typealias LocalizeDelegate = TransactionWalletCell

class TransactionWalletCell: UITableViewCell {
    @IBOutlet weak var transactionImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var cryptoAmountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var fiatAmountLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var emtptyImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    var histObj = HistoryRLM()
    var wallet = UserWalletRLM()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    public func fillCell() {
        if histObj.txStatus.intValue == TxStatus.MempoolIncoming.rawValue ||
            histObj.txStatus.intValue == TxStatus.MempoolOutcoming.rawValue {
            self.transactionImage.image = #imageLiteral(resourceName: "pending")
            let blockedTxInfoColor = UIColor(redInt: 135, greenInt: 161, blueInt: 197, alpha: 0.4)
            self.addressLabel.textColor = blockedTxInfoColor
            self.timeLabel.textColor = blockedTxInfoColor
            self.cryptoAmountLabel.textColor = blockedTxInfoColor
        } else if histObj.txStatus.intValue == TxStatus.BlockIncoming.rawValue ||
            histObj.txStatus.intValue == TxStatus.BlockConfirmedIncoming.rawValue {
            let blockedTxInfoColor = UIColor(redInt: 135, greenInt: 161, blueInt: 197, alpha: 0.4)
            self.transactionImage.image = #imageLiteral(resourceName: "arrowReceived")
            self.addressLabel.textColor = .black
            self.timeLabel.textColor = blockedTxInfoColor
            self.cryptoAmountLabel.textColor = .black
        } else if histObj.txStatus.intValue == TxStatus.BlockOutcoming.rawValue ||
            histObj.txStatus.intValue == TxStatus.BlockConfirmedOutcoming.rawValue {
            let blockedTxInfoColor = UIColor(redInt: 135, greenInt: 161, blueInt: 197, alpha: 0.4)
            self.transactionImage.image = #imageLiteral(resourceName: "arrowSended")
            self.addressLabel.textColor = .black
            self.timeLabel.textColor = blockedTxInfoColor
            self.cryptoAmountLabel.textColor = .black
        } else if histObj.txStatus.intValue == TxStatus.Rejected.rawValue || histObj.txStatus.intValue ==  TxStatus.BlockMethodInvocationFail.rawValue {
            self.transactionImage.image = #imageLiteral(resourceName: "warninngBig")
            self.addressLabel.textColor = .black
            self.timeLabel.textColor = .red
            self.cryptoAmountLabel.textColor = .black
            self.timeLabel.text = "Unable to send transaction"
        }
        
        let dateFormatter = Date.defaultGMTDateFormatter()
//        if histObj.isIncoming() {
////            self.addressLabel.text = histObj.txInputs[0].address
//            self.addressLabel.text = wallet.incomingTxAddress(for: histObj)
//        } else {
////            self.addressLabel.text = histObj.txOutputs[0].address
//            self.addressLabel.text = wallet.outcomingTxAddress(for: histObj)
//        }
        
        if histObj.txStatus.intValue < 0 /* rejected tx*/ {
            self.timeLabel.text = localize(string: Constants.unableToSendString)
        } else {
            self.timeLabel.text = dateFormatter.string(from: histObj.blockTime)
        }
        
        fillSpecificData()
    }
    
    func fillSpecificData() {
        fillAddressAndName()
        fillAmountInfo()
    }
    
    func fillAddressAndName() {
        let savedAddresses = DataManager.shared.savedAddresses
        var address = String()
        
        switch wallet.blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            if histObj.txInputs.count == 0 {
                return
            }
            
            if histObj.isIncoming() {
                address = histObj.txInputs[0].address
            } else {
                address = histObj.txOutputs[0].address
            }
        case BLOCKCHAIN_ETHEREUM:
            if histObj.isIncoming() {
                address = histObj.addressesArray.first!
            } else {
                address = histObj.addressesArray.last!
            }
        default:
            return
        }
        
        if let name = savedAddresses[address] {
            nameLabel.text = name
            changeTopConstraint(true)
        } else {
            nameLabel.text = ""
            changeTopConstraint(false)
        }
        self.addressLabel.text = address
    }
    
    func fillAmountInfo() {
        switch wallet.blockchainType.blockchain {
        case BLOCKCHAIN_BITCOIN:
            fillBitcoinCell()
        case BLOCKCHAIN_ETHEREUM:
            fillEthereumCell()
        default:
            return
        }
    }
    
    func fillEthereumCell() {
        let ethAmount = wallet.txAmount(histObj)
        let ethAmountString = ethAmount.cryptoValueString(for: BLOCKCHAIN_ETHEREUM)
        let labelsCryproText = ethAmountString + " " + wallet.cryptoName
        self.cryptoAmountLabel.text = labelsCryproText
        
        let fiatAmountString = (ethAmount * histObj.fiatCourseExchange).fiatValueString(for: BLOCKCHAIN_ETHEREUM)
        fiatAmountLabel.text = fiatAmountString + " " + wallet.fiatName
    }
    
    func fillBitcoinCell() {
        if histObj.txInputs.count == 0 {
            return
        }
        
        if histObj.txStatus.intValue == TxStatus.BlockOutcoming.rawValue ||
            histObj.txStatus.intValue == TxStatus.BlockConfirmedOutcoming.rawValue {
            let outgoingAmount = wallet.outgoingAmount(for: histObj).btcValue
            
            self.cryptoAmountLabel.text = "\(outgoingAmount.fixedFraction(digits: 8)) \(wallet.cryptoName)"
            self.fiatAmountLabel.text = "\((outgoingAmount * histObj.fiatCourseExchange).fixedFraction(digits: 2)) \(wallet.fiatName)"
        } else {
            self.cryptoAmountLabel.text = "\(histObj.txOutAmount.uint64Value.btcValue.fixedFraction(digits: 8)) \(wallet.cryptoName)"
            self.fiatAmountLabel.text = "\((histObj.txOutAmount.uint64Value.btcValue * histObj.fiatCourseExchange).fixedFraction(digits: 2)) \(wallet.fiatName)"
        }
    }
    
//    func setCorners() {
//        let maskPath = UIBezierPath.init(roundedRect: bounds,
//                                         byRoundingCorners:[.topLeft, .topRight],
//                                         cornerRadii: CGSize.init(width: 15.0, height: 15.0))
//        let maskLayer = CAShapeLayer()
//        maskLayer.frame = bounds
//        maskLayer.path = maskPath.cgPath
//        layer.mask = maskLayer
//    }
    
    func changeState(isEmpty: Bool) {
        self.transactionImage.isHidden = isEmpty
        self.addressLabel.isHidden = isEmpty
        self.cryptoAmountLabel.isHidden = isEmpty
        self.timeLabel.isHidden = isEmpty
        self.fiatAmountLabel.isHidden = isEmpty
//        self.descriptionLabel.isHidden = isEmpty
        self.emtptyImage.isHidden = !isEmpty
        self.nameLabel.isHidden = isEmpty
    }
    
    func changeTopConstraint(_ isThereName: Bool) {
        self.topConstraint.constant = isThereName ? 34 : 19
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Wallets"
    }
}
