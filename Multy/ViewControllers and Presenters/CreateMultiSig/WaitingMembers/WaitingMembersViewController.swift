//
//  WaitingMembersViewController.swift
//  Multy
//
//  Created by Artyom Alekseev on 04.07.2018.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import UIKit
import UICircularProgressRing

class WaitingMembersViewController: UIViewController, UITableViewDataSource {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var backRing: UICircularProgressRing!
    @IBOutlet weak var progressRing: UICircularProgressRing!
    @IBOutlet weak var membersInfoHolderView: UIView!
    @IBOutlet weak var membersInfoHolderViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var membersCounterHolderView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var joinedMembersLabel: UILabel!
    @IBOutlet weak var multiSigWalletName: UILabel!
    @IBOutlet weak var stateImageView: UIImageView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var invitationCodeBackgroundView: UIView!
    @IBOutlet weak var invitationCodeButton: UIButton!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var membersTableView: UITableView!
    
    var presenter = WaitingMembersPresenter()
    var lastPosition : CGPoint?
    
    var initialMembersInfoHolderHeight : CGFloat? {
        didSet {
            updateUI()
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        membersInfoHolderView.addGestureRecognizer(panGR)
        
        configureMembersInfoUI()
        
        presenter.viewController = self
        presenter.viewControllerViewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        initialMembersInfoHolderHeight = contentView.frame.size.height - (membersCounterHolderView.frame.origin.y + membersCounterHolderView.frame.size.height + 40)
        
        presenter.viewControllerViewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        updateUI()
        
        presenter.viewControllerViewWillAppear()
    }
    
    func configureMembersInfoUI() {
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
    }
    
    
    func updateUI() {
        multiSigWalletName.text = presenter.walletName
        
        joinedMembersLabel.text = "\(presenter.membersJoined) / \(presenter.membersAmount)"
        progressRing.endAngle = -90 + (CGFloat(presenter.membersJoined) / CGFloat(presenter.membersAmount) * 360)
        
        
        if (presenter.membersJoined == presenter.membersAmount) {
            stateImageView.image = UIImage(named: "readyToStart")
            stateLabel.text = "Ready to Start..."
            stateLabel.textColor = #colorLiteral(red: 0.8117647059, green: 1, blue: 0.8666666667, alpha: 1)
            invitationCodeButton.setTitle("Start for 0.001 BTC", for: .normal)
            backgroundView.backgroundColor = #colorLiteral(red: 0.3725490196, green: 0.8, blue: 0.4901960784, alpha: 1)
            qrCodeImageView.isHidden = true
        } else {
            stateImageView.image = UIImage(named: "pendingSmallClock")
            stateLabel.text = "Waiting for all members..."
            stateLabel.textColor = #colorLiteral(red: 0.5921568627, green: 0.8078431373, blue: 1, alpha: 1)
            invitationCodeButton.setTitle("Invitation Code", for: .normal)
            backgroundView.applyOrUpdateGradient(withColours: [
                UIColor(ciColor: CIColor(red: 29.0 / 255.0, green: 176.0 / 255.0, blue: 252.0 / 255.0)),
                UIColor(ciColor: CIColor(red: 21.0 / 255.0, green: 126.0 / 255.0, blue: 252.0 / 255.0))],
                                                 gradientOrientation: .topRightBottomLeft)
            qrCodeImageView.isHidden = false
        }
        
        invitationCodeBackgroundView.applyOrUpdateGradient(withColours: [
            UIColor(ciColor: CIColor(red: 29.0 / 255.0, green: 176.0 / 255.0, blue: 252.0 / 255.0)),
            UIColor(ciColor: CIColor(red: 21.0 / 255.0, green: 126.0 / 255.0, blue: 252.0 / 255.0))],
                                                           gradientOrientation: .topRightBottomLeft)
        
        contentView.layoutIfNeeded()
    }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer? = nil) {
        switch sender!.state {
        case .began:
            lastPosition = sender!.location(in: contentView)
            break
        case .changed:
            var membersInfoHolderViewHeight = membersInfoHolderViewHeightConstraint.constant
            let position = sender!.location(in: contentView)
            let translationRaw = position.y - lastPosition!.y
            if translationRaw > 0 {
                membersInfoHolderViewHeight -= (membersInfoHolderViewHeight - translationRaw) < initialMembersInfoHolderHeight! ? translationRaw / 2 : translationRaw
            } else {
                membersInfoHolderViewHeight -= translationRaw
                
                let topEdge = contentView.frame.size.height - (headerView.frame.origin.y + headerView.frame.size.height)
                if membersInfoHolderViewHeight > topEdge {
                    membersInfoHolderViewHeight = topEdge
                }
            }
            
            membersInfoHolderViewHeightConstraint.constant = membersInfoHolderViewHeight
            contentView.layoutIfNeeded()
            
            lastPosition = position
            break
            
        case .ended, .cancelled, .failed:
            var membersInfoHolderViewHeight = membersInfoHolderViewHeightConstraint.constant
            let topEdge = contentView.frame.size.height - (headerView.frame.origin.y + headerView.frame.size.height)
            let velocity = sender!.velocity(in: contentView)
            
            var animationDuration : TimeInterval = 0
            if abs(velocity.y) > 600.0 {
                animationDuration = 0.30
                
                if velocity.y < 0 {
                    membersInfoHolderViewHeight = topEdge
                } else {
                    membersInfoHolderViewHeight = initialMembersInfoHolderHeight!
                }
            } else {
                animationDuration = 0.2
                
                if membersInfoHolderViewHeight < initialMembersInfoHolderHeight! {
                    membersInfoHolderViewHeight = initialMembersInfoHolderHeight!
                } else {
                    if (contentView.frame.size.height - initialMembersInfoHolderHeight!) / 2 > contentView.frame.size.height - membersInfoHolderViewHeight {
                        membersInfoHolderViewHeight = contentView.frame.size.height - (headerView.frame.origin.y + headerView.frame.size.height)
                    } else {
                        membersInfoHolderViewHeight = initialMembersInfoHolderHeight!
                    }
                }
            }
            
            UIView.animate(withDuration: animationDuration) {
                self.membersInfoHolderViewHeightConstraint.constant = membersInfoHolderViewHeight
                self.contentView.layoutIfNeeded()
            }
            
            lastPosition = nil
            break
            
        default:
            break
        }
    }
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberCellReuseId")!
//        cell.contentView.backgroundColor = UIColor.init(red: CGFloat(arc4random() % 255) / 255, green: CGFloat(arc4random() % 255) / 255, blue: CGFloat(arc4random() % 255) / 255, alpha: 1)
        return cell
    }
    
    //MARK: Actions
    @IBAction func invitationCodeAction(_ sender: Any) {
        
    }
}
