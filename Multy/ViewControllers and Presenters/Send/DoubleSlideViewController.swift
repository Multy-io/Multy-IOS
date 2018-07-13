//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

protocol DoubleSliderDelegate: class {
    func didSlideToSend(_ sender: DoubleSlideViewController)
    func didSlideToDecline(_ sender: DoubleSlideViewController)
}

class DoubleSlideViewController: UIViewController {

    @IBOutlet weak var acceptSlideView: UIView!
    @IBOutlet weak var declineSlideView: UIView!
    @IBOutlet weak var slideTextLbl: UILabel!
    
    var forAccept = true
    var startSlideX: CGFloat = 0.0
    var isAnimateEnded = false
    var finishSlideX: CGFloat = screenWidth - 33
    
    var animateTimer: Timer?
    weak var delegate : DoubleSliderDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTimer()
        startSlideX = acceptSlideView.frame.origin.x
        let slideToSendGR = UIPanGestureRecognizer(target: self, action: #selector(slideToSend))
        acceptSlideView.addGestureRecognizer(slideToSendGR)
        
        let slideToDeclineGR = UIPanGestureRecognizer(target: self, action: #selector(slideToDecline(_ :)))
        declineSlideView.addGestureRecognizer(slideToDeclineGR)
    }
    
    func startTimer() {
        animateTimer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(animate), userInfo: nil, repeats: true)
    }
    
    @objc func animate() {
        UIView.animate(withDuration: 0.4, animations: {
            self.changeSlider(isForAccept: self.forAccept)
        })
    }
    
    func changeSlider(isForAccept: Bool) {
        acceptSlideView.isUserInteractionEnabled = !isForAccept
        acceptSlideView.alpha = isForAccept ? 0.2 : 1.0
        slideTextLbl.fadeTransition(0.4)
        slideTextLbl.text = isForAccept ? "Slide to Decline" : "Slide to Send"
        declineSlideView.alpha = isForAccept ? 1.0 : 0.2
        declineSlideView.isUserInteractionEnabled = isForAccept
        forAccept = !isForAccept
    }
    
    @IBAction func slideToSend(_ gestureRecognizer: UIPanGestureRecognizer) {
        animateTimer?.invalidate()
        let translation = gestureRecognizer.translation(in: self.view)
        if isAnimateEnded {
            return
        }
        if acceptSlideView.frame.maxX + translation.x >= finishSlideX {
            performSend()
            return
        }
        
        gestureRecognizer.view!.center = CGPoint(x: acceptSlideView.center.x + translation.x, y: acceptSlideView.center.y)
        gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        
        if gestureRecognizer.view!.frame.maxX < screenWidth / 2 {
            UIView.animate(withDuration: 0.3) {
                self.slideTextLbl.alpha = 0.5
            }
        } else if gestureRecognizer.view!.frame.maxX > screenWidth / 2 {
            UIView.animate(withDuration: 0.3) {
                self.slideTextLbl.alpha = 0
            }
        }
        
        if gestureRecognizer.state == .ended {
            if gestureRecognizer.view!.frame.origin.x < screenWidth / 2 {
                slideToStart()
            } else {
                performSend()
            }
        }
    }
    
    @objc func slideToDecline(_ gestureRecognizer: UIPanGestureRecognizer) {
        animateTimer?.invalidate()
        let translation = gestureRecognizer.translation(in: self.view)
        if isAnimateEnded {
            return
        }
        if declineSlideView.frame.origin.x + translation.x <= screenWidth - finishSlideX {
            performDecline()
            return
        }
        
        gestureRecognizer.view!.center = CGPoint(x: declineSlideView.center.x + translation.x, y: declineSlideView.center.y)
        gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        
        if gestureRecognizer.view!.frame.maxX > screenWidth / 2 {
            UIView.animate(withDuration: 0.3) {
                self.slideTextLbl.alpha = 0.5
            }
        } else if gestureRecognizer.view!.frame.maxX < screenWidth / 2 {
            UIView.animate(withDuration: 0.3) {
                self.slideTextLbl.alpha = 0
            }
        }
        
        if gestureRecognizer.state == .ended {
            if gestureRecognizer.view!.frame.maxX > screenWidth / 2 {
                slideToStart()
            } else {
                performDecline()
            }
        }
    }
    
    func slideToStart() {
        UIView.animate(withDuration: 0.3) {
            self.acceptSlideView.frame.origin.x = self.startSlideX
            self.declineSlideView.frame.origin.x = screenWidth - self.declineSlideView.frame.size.width
            self.slideTextLbl.alpha = 1.0
            self.isAnimateEnded = false
        }
        startTimer()
    }
    
    func performSend() {
        UIView.animate(withDuration: 0.3, animations: {
            self.isAnimateEnded = true
            self.acceptSlideView.frame.origin.x = screenWidth
            
        }) { succeeded in
            self.delegate?.didSlideToSend(self)
        }
    }
    
    func performDecline() {
        UIView.animate(withDuration: 0.3, animations: {
            self.isAnimateEnded = true
            self.declineSlideView.frame.origin.x = -self.declineSlideView.frame.size.width
            
        }) { succeeded in
            self.delegate?.didSlideToDecline(self)
        }
    }
}
