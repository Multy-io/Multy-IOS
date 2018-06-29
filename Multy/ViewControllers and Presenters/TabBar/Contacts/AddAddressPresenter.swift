//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class AddAddressPresenter: NSObject {
    var mainVC: AddAddressViewController?
    
    let blockchainData = Constants.DataManager.availableBlockchains
    
    var delegate: NewContactAddressProtocol?
}
