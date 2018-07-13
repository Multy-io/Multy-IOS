//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class MultiSigWalletCell: UITableViewCell {
    @IBOutlet weak var blockchainLabel: UILabel!
    @IBOutlet weak var blockchainImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setInfo(wallet: UserWalletRLM?) {
        if wallet == nil {
            blockchainImage.isHidden = true
            blockchainLabel.text = ""
        } else {
            blockchainImage.image = UIImage(named: wallet!.blockchainType.iconString)
            blockchainImage.isHidden = false
            blockchainLabel.text = wallet?.name
        }
    }
}
