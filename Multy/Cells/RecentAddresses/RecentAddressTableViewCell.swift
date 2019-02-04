//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
//import MultyCoreLibrary

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
        //repair old saving
        //change ERC20 to ETH
        if Blockchain(recentAddress.blockchain.uint32Value) == BLOCKCHAIN_ERC20 {
            let fixedBlockchainType = BlockchainType(blockchain: BLOCKCHAIN_ETHEREUM, net_type: recentAddress.blockchainNetType.intValue)
            createRecentAddress(recentAddress: recentAddress, with: fixedBlockchainType)
            
            cryptoImage.image = UIImage(named: fixedBlockchainType.iconString)
        } else {
            let blockchainType = BlockchainType.create(currencyID: recentAddress.blockchain.uint32Value, netType: recentAddress.blockchainNetType.uint32Value)
            cryptoImage.image = UIImage(named: blockchainType.iconString)
        }
        
        addressLbl.text = recentAddress.address
        
        let addresses = DataManager.shared.savedAddresses
        
        if let name = addresses[recentAddress.address] {
            addressNameLbl.text = name
            topConstraint.constant = 14
        } else {
            addressNameLbl.text = " "
            topConstraint.constant = 0
        }
    }
    
    func createRecentAddress(recentAddress: RecentAddressesRLM, with blockchainType: BlockchainType) {
        DataManager.shared.realmManager.writeOrUpdateRecentAddress(blockchainType: blockchainType,
                                                                   address: recentAddress.address,
                                                                   date: Date())
    }
}
