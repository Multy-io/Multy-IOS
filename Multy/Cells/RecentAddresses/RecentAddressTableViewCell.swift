//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class RecentAddressTableViewCell: UITableViewCell {

    @IBOutlet weak var cryptoImage: UIImageView!
    @IBOutlet weak var addressNameLbl: UILabel!
    @IBOutlet weak var addressLbl: UILabel!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillingCell(recentAddress: RecentAddressesRLM) {
        let blockchainType = BlockchainType.create(currencyID: recentAddress.blockchain.uint32Value, netType: recentAddress.blockchainNetType.uint32Value)
        addressLbl.text = recentAddress.address
        cryptoImage.image = UIImage(named: blockchainType.iconString)
        
        let addresses = DataManager.shared.savedAddresses?.addresses
        
        if addresses != nil, let name = addresses![recentAddress.address] {
            addressNameLbl.text = name
            topConstraint.constant = 14
        } else {
            addressNameLbl.text = " "
            topConstraint.constant = 0
        }
    }
    
}
