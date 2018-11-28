//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

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
        let seed = request!.requester == .wallet ? request!.choosenAddress!.address : request.userID.md5()
        requestImage.image  = PictureConstructor().createPicture(diameter: requestImage.frame.size.width, seed: seed)
        satisfiedImage.isHidden = !self.request.satisfied
    }
}

