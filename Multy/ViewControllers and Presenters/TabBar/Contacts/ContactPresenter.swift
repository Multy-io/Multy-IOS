//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class ContactPresenter: NSObject {
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
    
    func fillCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        cell.textLabel?.adjustsFontSizeToFitWidth = true
        
        let addressRLM = contact!.addresses[indexPath.row]
        
        cell.textLabel?.text = addressRLM.address
        let frame = cell.imageView!.frame
        cell.imageView!.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: 40, height: 40)
        cell.imageView!.image = UIImage(named: addressRLM.blockchainType.iconString)
    }
    
    func roundContactImage() {
        let height = (80.0 / 375.0) * screenWidth
        
        mainVC?.contactImageView.layer.cornerRadius = CGFloat(height / 2)
        mainVC?.contactImageView.clipsToBounds = true
        
        mainVC?.contactImageLabel.layer.cornerRadius = CGFloat(height / 2)
        mainVC?.contactImageLabel.clipsToBounds = true
    }
}
