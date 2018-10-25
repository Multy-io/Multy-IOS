//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = DonationCollectionViewCell

class DonationCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var backgroundImg: UIImageView!
    @IBOutlet weak var midLbl: UILabel!
    @IBOutlet weak var botView: UIView!
    @IBOutlet weak var bannerImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    func makeCellBy(index: Int) {
        switch index {
        case 0:
            self.bannerImg.isHidden = false
            self.bannerImg.image = UIImage(named: "multy-dragon-banner382")
//            self.bannerImg.image = UIImage(named: "grad")
//            self.bannerImg.layer.cornerRadius = 18
            self.bannerImg.layer.masksToBounds = true
//            setupUIfor(view: botView, color: #colorLiteral(red: 0.01194981113, green: 0.3642002213, blue: 0.9994105697, alpha: 0.5985124144))
            self.setupUIfor(view: botView, color: #colorLiteral(red: 0.6509803922, green: 0.6941176471, blue: 0.7764705882, alpha: 1))
        case 1:
            self.backgroundImg.image = #imageLiteral(resourceName: "portfolioDonationImage")
            self.midLbl.text = localize(string: Constants.cryptoPortfolioString)
            self.bannerImg.isHidden = true
            self.setupUIfor(view: botView, color: #colorLiteral(red: 0.6509803922, green: 0.6941176471, blue: 0.7764705882, alpha: 0.6))
        case 2:
            self.backgroundImg.image = #imageLiteral(resourceName: "chartsDonationImage")
            self.midLbl.text = localize(string: Constants.currenciesChartsString)
            self.bannerImg.isHidden = true
            self.setupUIfor(view: botView, color: #colorLiteral(red: 0.6509803922, green: 0.6941176471, blue: 0.7764705882, alpha: 0.6))
        default: break
        }
    }
    
    func setupUIfor(view: UIView, color: CGColor ) {
        view.layer.shadowColor = color
        view.layer.shadowOpacity = 1
        view.layer.shadowOffset = CGSize.zero
        view.layer.shadowRadius = 10
//        if screenHeight == heightOfiPad || screenHeight == heightOfFive {   // ipad fix
//            self.backgroundImg.contentMode = .scaleToFill
//        }
    }

}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}
