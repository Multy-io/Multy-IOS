//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Hash2Pics

enum ConfirmationStatus {
    case confirmed
    case declined
    case waiting
    case viewed
}

class ConfirmationStatusCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var memberPictureImageView: UIImageView!
    @IBOutlet weak var statusImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    
    
    func fill(address: String, status: ConfirmationStatus, memberName: String? = nil, date: Date? = nil) {
        let memberPicture = PictureConstructor().createPicture(diameter: memberPictureImageView.frame.size.width, seed: address)
        addressLabel.text = address
        memberPictureImageView.image = memberPicture
        let statusImg = statusImage(status)
        if statusImg != nil {
            statusImageView.isHidden = false
            statusImageView.image = statusImg
        } else {
            statusImageView.isHidden = true
        }
        
        statusLabel.attributedText = statusString(status: status, memberName: memberName, date: date)
    }
    
    private func statusString(status: ConfirmationStatus, memberName: String? = nil, date: Date? = nil) -> NSMutableAttributedString {
        let result = status == .waiting ? waitingConfirmationString(memberName: memberName) : checkedStatusesString(status, memberName: memberName, date: date!)
        return result
    }
    
    private func waitingConfirmationString(memberName: String? = nil) -> NSMutableAttributedString {
        let result = NSMutableAttributedString(string: "Waiting for confirmation…", attributes: [
            .font: UIFont(name: "AvenirNext-Regular", size: 12.0)!,
            .foregroundColor: UIColor(red: 132.0 / 255.0, green: 160.0 / 255.0, blue: 199.0 / 255.0, alpha: 1.0)])
        
        if memberName != nil {
            result.insert(NSAttributedString(string: " · ", attributes: [
                .font: UIFont(name: "AvenirNext-Regular", size: 12.0)!,
                .foregroundColor: UIColor(red: 132.0 / 255.0, green: 160.0 / 255.0, blue: 199.0 / 255.0, alpha: 1.0)]), at: 0)
            
            result.insert(NSAttributedString(string: "\(memberName!) ", attributes: [
                .font: UIFont(name: "AvenirNext-Regular", size: 12.0)!,
                .foregroundColor: UIColor(white: 54.0 / 255.0, alpha: 1.0)]), at: 0)
        }
        
        return result
    }
    
    private func checkedStatusesString(_ status: ConfirmationStatus, memberName: String? = nil, date: Date) -> NSMutableAttributedString {
        let dateFormatter = Date.defaultGMTDateFormatter()
        let dateString = dateFormatter.string(from: date)
        let result = NSMutableAttributedString(string: "· \(dateString)", attributes: [
            .font: UIFont(name: "AvenirNext-Regular", size: 12.0)!,
            .foregroundColor: UIColor(red: 132.0 / 255.0, green: 160.0 / 255.0, blue: 199.0 / 255.0, alpha: 1.0)])
        if memberName != nil {
            result.insert(NSAttributedString(string: "· \(memberName!) ", attributes: [
                .font: UIFont(name: "AvenirNext-Regular", size: 12.0)!,
                .foregroundColor: UIColor(white: 54.0 / 255.0, alpha: 1.0)]), at: 0)
        }
        
        var statusString = ""
        var statusColor = UIColor()
        var statusFont = UIFont()
        switch status {
        case .confirmed:
            statusString = "Confirmed"
            statusColor = UIColor(red: 95.0 / 255.0, green: 204.0 / 255.0, blue: 125.0 / 255.0, alpha: 1.0)
            statusFont = UIFont(name: "AvenirNext-Medium", size: 12.0)!
            break
            
        case .declined:
            statusString = "Declined"
            statusColor = UIColor(red: 95.0 / 255.0, green: 204.0 / 255.0, blue: 125.0 / 255.0, alpha: 1.0)
            statusFont = UIFont(name: "AvenirNext-Medium", size: 12.0)!
            break
            
        case .viewed:
            statusString = "Viewed"
            statusColor = UIColor(red: 132.0 / 255.0, green: 160.0 / 255.0, blue: 199.0 / 255.0, alpha: 1.0)
            statusFont = UIFont(name: "AvenirNext-Regular", size: 12.0)!
            break
            
        default:
            break
        }
        
        result.insert(NSAttributedString(string: "\(statusString) ", attributes: [
            .font: statusFont,
            .foregroundColor: statusColor]), at: 0)
        
        return result
    }
    
    private func statusImage(_ status: ConfirmationStatus) -> UIImage? {
        var imageName : String? = nil
        switch status {
        case .confirmed:
            imageName = "memberStatusConfirmed"
            break
            
        case .declined:
            imageName = "memberStatusDeclined"
            break
            
        case .viewed:
            imageName = "memberStatusViewed"
            break
            
        case .waiting:
            imageName = ""
            break
            
        default:
            break
        }
        
        var result : UIImage?
        if imageName != nil {
            result = UIImage(named: imageName!)
        }
        
        return result
    }
}
