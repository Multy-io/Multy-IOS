//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CreateMultiSigPresenter: NSObject, CountOfProtocol {
    var mainVC: CreateMultiSigViewController?
    
    var membersCount = 2
    var signaturesCount = 2
    var walletName: String = ""
    var selectedBlockchainType = BlockchainType.init(blockchain: BLOCKCHAIN_ETHEREUM, net_type: Int(ETHEREUM_CHAIN_ID_RINKEBY.rawValue))
    var choosenWallet: UserWalletRLM? {
        didSet {
            mainVC?.tableView.reloadData()
        }
    }
    
    func passMultiSigInfo(signaturesCount: Int, membersCount: Int) {
        self.signaturesCount = signaturesCount
        self.membersCount = membersCount
        
        mainVC?.tableView.reloadData()
    }
}
