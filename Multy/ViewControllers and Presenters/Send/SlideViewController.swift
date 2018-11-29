//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Lottie

protocol SliderDelegate: class {
    func didSlideToSend(_ sender: SlideViewController)
}

class SlideViewController: UIViewController {
    
    @IBOutlet weak var slideToSendLabel: UILabel!
    @IBOutlet weak var slideView: UIView!
    @IBOutlet weak var slideAnimationHolderView: UIView!
    var slideToSendAnimationView : LOTAnimationView?
    
    var startSlideX: CGFloat = 0.0
    var isAnimateEnded = false
    var finishSlideX: CGFloat = screenWidth - 33
    
    var animateTimer: Timer?
    weak var delegate : SliderDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(slideToSend))
        slideView.isUserInteractionEnabled = true
        slideView.addGestureRecognizer(gestureRecognizer)
        
        
        startSlideX = slideView.frame.origin.x
        let slideToSendGR = UIPanGestureRecognizer(target: self, action: #selector(slideToSend))
        slideView.addGestureRecognizer(slideToSendGR)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if slideToSendAnimationView == nil {
            slideToSendAnimationView = LOTAnimationView(name: "sendTipAnimation")
            slideToSendAnimationView!.frame = slideAnimationHolderView.bounds
            slideAnimationHolderView.autoresizesSubviews = true
            slideAnimationHolderView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            slideAnimationHolderView.insertSubview(slideToSendAnimationView!, at: 0)
            
            slideToSendAnimationView!.loopAnimation = true
            slideToSendAnimationView!.play()
        }
    }
    
    @IBAction func slideToSend(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: self.view)
        if isAnimateEnded {
            return
        }
        if slideView.frame.maxX + translation.x >= finishSlideX {
            performSend()
            return
        }
        
        gestureRecognizer.view!.center = CGPoint(x: slideView.center.x + translation.x, y: slideView.center.y)
        gestureRecognizer.setTranslation(CGPoint.zero, in: self.view)
        
        if gestureRecognizer.view!.frame.maxX < screenWidth / 2 {
            UIView.animate(withDuration: 0.3) {
                self.slideToSendLabel.alpha = 0.5
            }
        } else if gestureRecognizer.view!.frame.maxX > screenWidth / 2 {
            UIView.animate(withDuration: 0.3) {
                self.slideToSendLabel.alpha = 0
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
    
    func updateToInitialState() {
        isAnimateEnded = false
        slideToStart()
    }
    
    func slideToStart() {
        UIView.animate(withDuration: 0.3) {
            self.slideView.frame.origin.x = self.startSlideX
            self.slideToSendLabel.alpha = 1.0
            self.isAnimateEnded = false
        }
    }
    
    func performSend() {
        UIView.animate(withDuration: 0.3, animations: {
            self.isAnimateEnded = true
            self.slideView.frame.origin.x = screenWidth
            
        }) { succeeded in
            self.delegate?.didSlideToSend(self)
        }
    }
}
