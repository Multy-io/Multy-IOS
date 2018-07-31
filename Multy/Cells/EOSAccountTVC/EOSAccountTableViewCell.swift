//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class EOSAccountTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    
    func fill(name: String) {
        nameLabel.text = name
    }
}
