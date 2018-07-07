//
//  ActiveRequestCollectionViewCell.swift
//  Multy
//
//  Created by Artyom Alekseev on 16.05.2018.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import UIKit
import Lottie
import Hash2Pics

class ActiveRequestCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var requestImage: UIImageView!
    @IBOutlet weak var satisfiedImage: UIImageView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        requestImage.layer.cornerRadius = requestImage.frame.size.width/2
        requestImage.layer.masksToBounds = true
        satisfiedImage.layer.cornerRadius = satisfiedImage.frame.size.width/2
        satisfiedImage.layer.masksToBounds = true
    }

    var request : PaymentRequest!
    
    func fillInCell() {
        requestImage.image  = PictureConstructor().createPicture(diameter: requestImage.frame.size.width, seed: request!.sendAddress)
        satisfiedImage.isHidden = !self.request.satisfied
    }
}

