//
//  WaitingMembersViewController.swift
//  Multy
//
//  Created by Artyom Alekseev on 04.07.2018.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import UIKit
import UICircularProgressRing

class WaitingMembersViewController: UIViewController {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backRing: UICircularProgressRing!
    @IBOutlet weak var progressRing: UICircularProgressRing!
    @IBOutlet weak var usersInfoHolderView: UIView!
    @IBOutlet weak var usersInfoHoderViewHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var usersCounterHolderView: UIView!
    @IBOutlet weak var headerView: UIView!
    
    var initialUsersInfoHolderHeight : CGFloat? {
        didSet {
            updateUI()
        }
    }
    
    var participantsAmount : UInt?
    var participantsJoined : UInt?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backRing.ringStyle = .dashed
        backRing.outerRingColor = .white
        backRing.outerRingWidth = 1
        backRing.outerCapStyle = .round
        backRing.fullCircle = true
        
        progressRing.shouldShowValueText = false
        progressRing.ringStyle = .ontop
        progressRing.outerRingColor = .white
        progressRing.outerRingWidth = 3
        progressRing.outerCapStyle = .round
        progressRing.fullCircle = false
        progressRing.startAngle = -90
        progressRing.endAngle = 0
        
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        usersInfoHolderView.addGestureRecognizer(panGR)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        initialUsersInfoHolderHeight = contentView.frame.size.height - (usersCounterHolderView.frame.origin.y + usersCounerHolderView.frame.size.height + 20)
    }
    
    func updateUI() {
        
        self.contentView.layoutIfNeeded()
    }
    
    var lastPosition : CGPoint?
    @objc func handlePan(_ sender: UIPanGestureRecognizer? = nil) {
        switch sender!.state {
        case .began:
            lastPosition = sender!.location(in: contentView)
            break
        case .changed:
            var usersInfoHolderViewHeight = usersInfoHolderViewHeightConstraint.constant
            let position = sender!.location(in: contentView)
            let translationRaw = position.y - lastPosition!.y
            if translationRaw > 0 {
                usersInfoHolderViewHeight -= (usersInfoHolderViewHeight - translationRaw) < initialUsersInfoHolderHeight! ? translationRaw / 2 : translationRaw
            } else {
                usersInfoHolderViewHeight -= translationRaw
                
                let topEdge = contentView.frame.size.height - (headerView.frame.origin.y + headerView.frame.size.height)
                if usersInfoHolderViewHeight > topEdge {
                    usersInfoHolderViewHeight = topEdge
                }
            }
            
            usersInfoHolderViewHeightConstraint.constant = usersInfoHolderViewHeight
            contentView.layoutIfNeeded()
            
            lastPosition = position
            break
            
        case .ended, .cancelled, .failed:
            var usersInfoHolderViewHeight = usersInfoHolderViewHeightConstraint.constant
            let topEdge = contentView.frame.size.height - (headerView.frame.origin.y + headerView.frame.size.height)
            let velocity = sender!.velocity(in: contentView)
            
            var animationDuration : TimeInterval = 0
            if abs(velocity.y) > 1000.0 {
                animationDuration = 0.35
                
                if velocity.y < 0 {
                    usersInfoHolderViewHeight = topEdge
                } else {
                    usersInfoHolderViewHeight = initialUsersInfoHolderHeight!
                }
            } else {
                animationDuration = 0.2
                
                if usersInfoHolderViewHeight < initialUsersInfoHolderHeight! {
                    usersInfoHolderViewHeight = initialUsersInfoHolderHeight!
                } else {
                    if (contentView.frame.size.height - initialUsersInfoHolderHeight!) / 2 > contentView.frame.size.height - usersInfoHolderViewHeight {
                        usersInfoHolderViewHeight = contentView.frame.size.height - (headerView.frame.origin.y + headerView.frame.size.height)
                    } else {
                        usersInfoHolderViewHeight = initialUsersInfoHolderHeight!
                    }
                }
            }
            
            UIView.animate(withDuration: animationDuration) {
                self.usersInfoHolderViewHeightConstraint.constant = usersInfoHolderViewHeight
                self.contentView.layoutIfNeeded()
            }
            
            lastPosition = nil
            break
            
        default:
            break
        }
    }
}
