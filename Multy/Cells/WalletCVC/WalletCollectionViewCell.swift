//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Lottie
//import MultyCoreLibrary

class WalletCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var tokenImage: UIImageView!
    @IBOutlet weak var walletNameLbl: UILabel!
    @IBOutlet weak var cryptoSumLbl: UILabel!
    @IBOutlet weak var cryptoNameLbl: UILabel!
    @IBOutlet weak var fiatSumLbl: UILabel!
    @IBOutlet weak var viewForShadow: UIView!
    
    var wallet: UserWalletRLM?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupShadow()
    }
    
    func setupShadow() {
        viewForShadow.setShadow(with: #colorLiteral(red: 0.6509803922, green: 0.6941176471, blue: 0.7764705882, alpha: 0.6))
    }
    
    func fillInCell() {
        let blockchainType = BlockchainType.createAssociated(wallet: wallet!)
        
        tokenImage.image = UIImage(named: blockchainType.iconString)
        
        if wallet!.isTokenWallet {
            tokenImage.moa.url = wallet!.token?.tokenImageURLString
            walletNameLbl.text = wallet!.tokenHolderWallet!.name
            
            cryptoNameLbl.text = wallet!.token!.ticker
            
            cryptoSumLbl.text  = wallet!.availableAmount.cryptoValueString(for: wallet!.token)
            fiatSumLbl.isHidden = true
        } else {
            walletNameLbl.text = wallet!.name
            
            cryptoSumLbl.text  = wallet!.availableAmount.cryptoValueString(for: blockchainType.blockchain)
            cryptoNameLbl.text = blockchainType.shortName
            
            let sumInFiat = wallet!.sumInFiat.fixedFraction(digits: 2)
            fiatSumLbl.isHidden = false
            fiatSumLbl.text = "\(sumInFiat) \(self.wallet!.fiatSymbol)"
        }
    }
}
