//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class NewExchangeWalletTableViewCell: UITableViewCell {

    @IBOutlet weak var insideView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setGradient() {
        insideView.applyGradient(withColours: [UIColor(ciColor: CIColor(red: 0/255, green: 178/255, blue: 255/255)),
                                         UIColor(ciColor: CIColor(red: 0/255, green: 122/255, blue: 255/255))],
                           gradientOrientation: .horizontal)
    }
    
}
