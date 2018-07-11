//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class CreateMultiSigPresenter: NSObject, CountOfProtocol {

    var mainVC: CreateMultiSigViewController?
    
    var countOfMembers = 2
    var countOfSigns = 2
    var walletName: String = ""
    
    func countSomething(tag: String?, count: Int) {
        if tag == "members" {
            countOfMembers = count
            
            if countOfMembers < countOfSigns {
                countOfSigns = countOfMembers
            }
        } else if tag == "signs" {
            countOfSigns = count
            
            if countOfSigns > countOfMembers {
                countOfMembers = countOfSigns
            }
        }
        mainVC?.tableView.reloadData()
    }
}
