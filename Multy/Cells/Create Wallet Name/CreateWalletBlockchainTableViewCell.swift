//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CreateWalletBlockchainTableViewCell: UITableViewCell {
    @IBOutlet weak var blockchainLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setLblValue(value: String?) {
        if value != nil && blockchainLabel != nil {
            blockchainLabel.text = value
        }
    }
}
