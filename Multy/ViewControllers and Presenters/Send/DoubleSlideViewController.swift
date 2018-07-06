//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

class DoubleSlideViewController: UIViewController {

    @IBOutlet weak var acceptSlideView: UIView!
    @IBOutlet weak var declineSlideView: UIView!
    @IBOutlet weak var slideTextLbl: UILabel!
    
    var forAccept = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let _ = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(animate), userInfo: nil, repeats: true)
        
    }
    
    @objc func animate() {
        UIView.animate(withDuration: 0.4, animations: {
            self.changeSlider(isForAccept: self.forAccept)
        })
    }
    
    func changeSlider(isForAccept: Bool) {
        acceptSlideView.isUserInteractionEnabled = isForAccept
        acceptSlideView.alpha = isForAccept ? 0.2 : 1.0
        slideTextLbl.fadeTransition(0.4)
        slideTextLbl.text = isForAccept ? "Slide to Decline" : "Slide to Send"
        declineSlideView.alpha = isForAccept ? 1.0 : 0.2
        declineSlideView.isUserInteractionEnabled = !isForAccept
        forAccept = !isForAccept
    }
}
