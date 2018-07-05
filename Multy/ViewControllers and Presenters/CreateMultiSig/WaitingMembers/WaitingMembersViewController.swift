//
//  WaitingMembersViewController.swift
//  Multy
//
//  Created by Artyom Alekseev on 04.07.2018.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

import UIKit
import UICircularProgressRing
import Hash2Pics

private typealias LocalizeDelegate = WaitingMembersViewController

class WaitingMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var backRing: UICircularProgressRing!
    @IBOutlet weak var progressRing: UICircularProgressRing!
    @IBOutlet weak var membersInfoHolderView: UIView!
    @IBOutlet weak var membersInfoHolderViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var membersInfoTouchpadView: UIView!
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
    
    var membersInfoHolderViewHeight : CGFloat = 0 {
        didSet {
            updateMembersCounterOpacity()
            membersTableView.isUserInteractionEnabled = membersInfoHolderViewHeight == topEdge ? true : false
            membersInfoTouchpadView.isUserInteractionEnabled = membersInfoHolderViewHeight == topEdge ? false : true
            membersInfoHolderViewHeightConstraint.constant = membersInfoHolderViewHeight
            contentView.layoutIfNeeded()
        }
    }
    
    var lastPosition : CGPoint?
    
    var initialMembersInfoHolderHeight : CGFloat = 0 {
        didSet {
            if oldValue != initialMembersInfoHolderHeight {
                membersInfoHolderViewHeight = initialMembersInfoHolderHeight
            }
        }
    }
    
    var topEdge : CGFloat {
        return contentView.frame.size.height - (headerView.frame.origin.y + headerView.frame.size.height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        membersInfoTouchpadView.addGestureRecognizer(panGR)
        let memberCell = UINib.init(nibName: "MemberTableViewCell", bundle: nil)
        membersTableView.register(memberCell, forCellReuseIdentifier: "memberTVCReuseId")
        
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
        
        joinedMembersLabel.text = "\(presenter.membersJoined.count) / \(presenter.membersAmount)"
        progressRing.endAngle = -90 + (CGFloat(presenter.membersJoined.count) / CGFloat(presenter.membersAmount) * 360)
        
        
        if (presenter.membersJoined.count == presenter.membersAmount) {
            stateImageView.image = UIImage(named: "readyToStart")
            stateLabel.text = localize(string: Constants.readyToStartString)
            stateLabel.textColor = #colorLiteral(red: 0.8117647059, green: 1, blue: 0.8666666667, alpha: 1)
            invitationCodeButton.setTitle("\(Constants.startForString) \(presenter.createWalletPrice) BTC", for: .normal)
            backgroundView.backgroundColor = #colorLiteral(red: 0.3725490196, green: 0.8, blue: 0.4901960784, alpha: 1)
            qrCodeImageView.isHidden = true
        } else {
            stateImageView.image = UIImage(named: "pendingSmallClock")
            stateLabel.text = localize(string: Constants.waitingAllMembersString)
            stateLabel.textColor = #colorLiteral(red: 0.5921568627, green: 0.8078431373, blue: 1, alpha: 1)
            invitationCodeButton.setTitle(localize(string: Constants.invitationCodeString), for: .normal)
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
    
    func updateMembersCounterOpacity() {
        let rangeRaw = topEdge - initialMembersInfoHolderHeight
        var value = membersInfoHolderViewHeight
        if value < initialMembersInfoHolderHeight {
            value = initialMembersInfoHolderHeight
        }
        if value > topEdge {
            value = topEdge
        }
        
        membersCounterHolderView.alpha = 1 - (value - initialMembersInfoHolderHeight) / rangeRaw
    }
    
    @objc private func handlePan(_ sender: UIPanGestureRecognizer? = nil) {
        switch sender!.state {
        case .began:
            lastPosition = sender!.location(in: contentView)
            break
        case .changed:
            var membersInfoHolderViewHeight = self.membersInfoHolderViewHeight
            let position = sender!.location(in: contentView)
            let translationRaw = position.y - lastPosition!.y
            if translationRaw > 0 {
                membersInfoHolderViewHeight -= (membersInfoHolderViewHeight - translationRaw) < initialMembersInfoHolderHeight ? translationRaw / 2 : translationRaw
            } else {
                membersInfoHolderViewHeight -= translationRaw
                
                if membersInfoHolderViewHeight > topEdge {
                    membersInfoHolderViewHeight = topEdge
                }
            }
            
            self.membersInfoHolderViewHeight = membersInfoHolderViewHeight
            
            lastPosition = position
            break
            
        case .ended, .cancelled, .failed:
            var membersInfoHolderViewHeight = self.membersInfoHolderViewHeight
            let velocity = sender!.velocity(in: contentView)
            
            var animationDuration : TimeInterval = 0
            if abs(velocity.y) > 600.0 {
                animationDuration = 0.30
                
                if velocity.y < 0 {
                    membersInfoHolderViewHeight = topEdge
                } else {
                    membersInfoHolderViewHeight = initialMembersInfoHolderHeight
                }
            } else {
                animationDuration = 0.2
                
                if membersInfoHolderViewHeight < initialMembersInfoHolderHeight {
                    membersInfoHolderViewHeight = initialMembersInfoHolderHeight
                } else {
                    if (contentView.frame.size.height - initialMembersInfoHolderHeight) / 2 > contentView.frame.size.height - membersInfoHolderViewHeight {
                        membersInfoHolderViewHeight = topEdge
                    } else {
                        membersInfoHolderViewHeight = initialMembersInfoHolderHeight
                    }
                }
            }
            
            UIView.animate(withDuration: animationDuration) {
                self.membersInfoHolderViewHeight = membersInfoHolderViewHeight
            }
            
            lastPosition = nil
            break
            
        default:
            break
        }
    }
    
    func openShareInviteVC() {
        let storyBoard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
        let inviteCodeVC = storyBoard.instantiateViewController(withIdentifier: "inviteCodeVC")
        present(inviteCodeVC, animated: true, completion: nil)
    }
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(presenter.membersAmount)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberTVCReuseId")! as! MemberTableViewCell
        if (indexPath.item + 1) > presenter.membersJoined.count {
            cell.fillWaitingMember()
        } else {
            let memberAddress = presenter.membersJoined[indexPath.item]
            let memberImage = PictureConstructor().createPicture(diameter: 34, seed: memberAddress)
            cell.fillWithMember(address: memberAddress, image: memberImage!, isCurrentUser: true)
        }
        cell.hideSeparator = indexPath.item == (presenter.membersAmount - 1)
        
        return cell
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

            //TODO: remove the item from the data model
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        var membersInfoHolderViewHeight = self.membersInfoHolderViewHeight
        if scrollView.contentOffset.y < 0 {
            membersInfoHolderViewHeight += scrollView.contentOffset.y
            
            self.membersInfoHolderViewHeight = membersInfoHolderViewHeight
        } else {
            if membersInfoHolderViewHeight != topEdge {
                membersInfoHolderViewHeight += scrollView.contentOffset.y
                if membersInfoHolderViewHeight > topEdge {
                    membersInfoHolderViewHeight = topEdge
                }
                
                self.membersInfoHolderViewHeight = membersInfoHolderViewHeight
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        var membersInfoHolderViewHeight = self.membersInfoHolderViewHeight
        if membersInfoHolderViewHeight < initialMembersInfoHolderHeight {
            membersInfoHolderViewHeight = initialMembersInfoHolderHeight
        } else {
            if (contentView.frame.size.height - initialMembersInfoHolderHeight) / 2 > contentView.frame.size.height - membersInfoHolderViewHeight {
                membersInfoHolderViewHeight = topEdge
            } else {
                membersInfoHolderViewHeight = initialMembersInfoHolderHeight
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.membersInfoHolderViewHeight = membersInfoHolderViewHeight
        }
    }
    
    //MARK: Actions
    @IBAction func invitationCodeAction(_ sender: Any) {
        
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "CreateMultiSig"
    }
}
