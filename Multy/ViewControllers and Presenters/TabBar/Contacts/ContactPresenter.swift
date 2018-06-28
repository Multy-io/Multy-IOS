//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = ContactPresenter

class ContactPresenter: NSObject, ContactsProtocol {
    var contact: EPContact?
    var indexPath: IndexPath?
    var mainVC: ContactViewController?
    
    func fillContactImage() {
        if contact!.thumbnailProfileImage != nil {
            mainVC!.contactImageView.image = contact!.thumbnailProfileImage
            mainVC!.contactImageView.isHidden = false
            mainVC!.contactImageLabel.isHidden = true
        } else {
            mainVC!.contactImageLabel.text = contact?.contactInitials()
            updateInitialsColorForIndexPath(indexPath!)
            mainVC!.contactImageView.isHidden = true
            mainVC!.contactImageLabel.isHidden = false
        }
    }
    
    func updateInitialsColorForIndexPath(_ indexpath: IndexPath) {
        //Applies color to Initial Label
        let colorArray = [EPGlobalConstants.Colors.amethystColor,EPGlobalConstants.Colors.asbestosColor,EPGlobalConstants.Colors.emeraldColor,EPGlobalConstants.Colors.peterRiverColor,EPGlobalConstants.Colors.pomegranateColor,EPGlobalConstants.Colors.pumpkinColor,EPGlobalConstants.Colors.sunflowerColor]
        let randomValue = (indexpath.row + indexpath.section) % colorArray.count
        mainVC!.contactImageLabel.backgroundColor = colorArray[randomValue]
    }
    
    func fillCell(_ cell: ContactCell, at indexPath: IndexPath) {
        let addressRLM = contact!.addresses[indexPath.row]
        
        cell.contactAddressLabel.text = addressRLM.address
        cell.contactImageView.image = UIImage(named: addressRLM.blockchainType.iconString)
    }
    
    func roundContactImage() {
        let height = (80.0 / 375.0) * screenWidth
        
        mainVC?.contactImageView.layer.cornerRadius = CGFloat(height / 2)
        mainVC?.contactImageView.clipsToBounds = true
        
        mainVC?.contactImageLabel.layer.cornerRadius = CGFloat(height / 2)
        mainVC?.contactImageLabel.clipsToBounds = true
    }
    
    func tappedCell(at IndexPath: IndexPath) {
        let title = contact!.addresses[IndexPath.row].address
        let actionSheet = UIAlertController(title: "", message: title, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: localize(string: Constants.cancelString), style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: localize(string: Constants.deleteFromContact), style: .default, handler: { [unowned self] (action) in
            self.mainVC?.view.isUserInteractionEnabled = false
            self.deleteAddress(title, from: self.contact!.contactId!, { (result) in
                self.fetchPhoneContact(self.contact!.contactId!, completion: { (contact, error) in
                    DispatchQueue.main.async {
                        if contact != nil {
                            self.contact = EPContact.init(contact: contact!)
                        }
                        
                        self.mainVC!.tableView.reloadData()
                        self.mainVC!.view.isUserInteractionEnabled = true
                    }
                })
            })
        }))
        mainVC?.present(actionSheet, animated: true, completion: nil)
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Contacts"
    }
}
