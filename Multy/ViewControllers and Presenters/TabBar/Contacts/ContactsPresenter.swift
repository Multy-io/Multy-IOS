//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ContactsPresenter: NSObject, ContactsProtocol {
    var mainVC: ContactsViewController?
    
    var tabBarFrame: CGRect?
    var contacts = [EPContact]() {
        didSet {
            mainVC?.tableView.reloadData()
        }
    }
    
    func registerCell() {
        let cellNib = UINib(nibName: "EPContactCell", bundle: nil)
        mainVC?.tableView.register(cellNib, forCellReuseIdentifier: "Cell")
    }
    
    func fetchPhoneContacts() {
        fetchPhoneContacts { [unowned self] (contacts, error) in
            if error == nil && contacts != nil {
                let multyContacts = contacts!.filter { $0.isMulty() }
                
                DispatchQueue.main.async {
                    self.contacts = EPContact.initFromArray(multyContacts).sorted {
                        $0.displayName().lowercased().compare($1.displayName().lowercased()).rawValue <= 0
                    }
                }
            }
        }
    }
}
