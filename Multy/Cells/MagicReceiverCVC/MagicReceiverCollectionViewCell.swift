//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Lottie

class MagicReceiverCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var requestImageHolderView: UIView!
    @IBOutlet weak var requestImageView: UIImageView!
    @IBOutlet weak var turnOnBluetoothLabel: UILabel!
    
    var wavesAnimationView : LOTAnimationView?
    private var bluetoothEnabled = true
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if wavesAnimationView == nil {
            wavesAnimationView = LOTAnimationView(name: "circle_grow")
            requestImageHolderView.insertSubview(wavesAnimationView!, at: 0)
            wavesAnimationView!.loopAnimation = true
        }
        
        updateUI()
    }
    
    func fillWithBluetoothState(_ bluetoothState: Bool, requestImage: UIImage?) {
        bluetoothEnabled = bluetoothState
        requestImageView.image = bluetoothEnabled ? requestImage : #imageLiteral(resourceName: "bluetooth_disabled_img")
        turnOnBluetoothLabel.isHidden = bluetoothEnabled ? true : false
        updateUI()
    }
    
    func updateUI() {
        if wavesAnimationView != nil {
            wavesAnimationView!.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.width)
            wavesAnimationView!.center = requestImageView.center
            
            if bluetoothEnabled {
                if !wavesAnimationView!.isAnimationPlaying {
                    wavesAnimationView!.play()
                }
            } else {
                if wavesAnimationView!.isAnimationPlaying {
                    wavesAnimationView!.stop()
                }
            }
        }
    }
}
