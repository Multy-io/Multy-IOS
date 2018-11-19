//
//  TokenTableViewCell.swift
//  Multy
//
//  Created by Andrey Apet on 10/10/18.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import UIKit
import moa

class TokenTableViewCell: UITableViewCell {

    @IBOutlet weak var tokenImg: UIImageView!
    @IBOutlet weak var tokenName: UILabel!
    @IBOutlet weak var cryptoAmountLbl: UILabel!  // + eth
    @IBOutlet weak var fiatAmountLbl: UILabel!    // + usd
    
    var tokenObj = WalletTokenRLM()
    
    var exchangeCourse: Double {
        get {
            return DataManager.shared.makeExchangeFor(blockchainType: BlockchainType.create(currencyID: 60, netType: 1))
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func fillingCell(tokenObj: WalletTokenRLM) {
        //set token img
        let ethBalance = tokenObj.balanceBigInt
        
        if let token = tokenObj.token, token.isUpdated {
            tokenName.text = token.name
            cryptoAmountLbl.text = ethBalance.cryptoValueString(for: token) + " " + token.ticker
        } else {
            tokenName.text = tokenObj.name
            cryptoAmountLbl.text = ethBalance.cryptoValueString(for: BLOCKCHAIN_ETHEREUM) + " " + tokenObj.ticker
        }
        
        fiatAmountLbl.isHidden = true
        
        tokenImg.image = UIImage(named: "chainEth")
        tokenImg.moa.url = tokenObj.tokenImageURLString
        
//        let fiatBalance = ethBalance * exchangeCourse
//        fiatAmountLbl.text = "\(fiatBalance.fiatValueString(for: BLOCKCHAIN_ETHEREUM)) USD"
    }
    
}
