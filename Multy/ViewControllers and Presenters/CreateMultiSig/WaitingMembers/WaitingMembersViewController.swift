//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import UICircularProgressRing
import Hash2Pics

private typealias LocalizeDelegate = WaitingMembersViewController

class WaitingMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var backgroundView: UIView!
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
    @IBOutlet weak var invitationHolderView: UIView!
    
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
//        membersInfoTouchpadView.addGestureRecognizer(panGR)
        registerCells()
        initialConfig()
        
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
        
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        updateUI()
        
        presenter.viewControllerViewWillAppear()
    }
    
    func initialConfig() {
        progressRing.shouldShowValueText = false
        progressRing.ringStyle = .dashed
        progressRing.outerRingColor = .white
        progressRing.innerRingColor = .white
        progressRing.outerRingWidth = 1
        progressRing.outerCapStyle = .round
        progressRing.fullCircle = true
        progressRing.minValue = 0
        progressRing.maxValue = 360
        progressRing.startAngle = -90

        membersTableView.contentInset = UIEdgeInsetsMake(0, 0, invitationCodeButton.frame.size.height, 0)
    }
    
    func registerCells() {
        let memberCell = UINib.init(nibName: "MemberTableViewCell", bundle: nil)
        membersTableView.register(memberCell, forCellReuseIdentifier: "memberTVCReuseId")
    }
    
    func updateUI() {
        multiSigWalletName.text = presenter.wallet.name
        
        let joinedCount = presenter.wallet.multisigWallet!.owners.count
        let totalCount = presenter.wallet.multisigWallet!.ownersCount
        joinedMembersLabel.text = "\(joinedCount) / \(totalCount)"
        progressRing.value = CGFloat(joinedCount) / CGFloat(totalCount) * 360
        
        if (joinedCount == totalCount) {
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
        
        if presenter.wallet.multisigWallet!.amICreator {
            invitationHolderView.isHidden = false
            invitationHolderView.isUserInteractionEnabled = true
            invitationCodeBackgroundView.applyOrUpdateGradient(withColours: [
                UIColor(ciColor: CIColor(red: 29.0 / 255.0, green: 176.0 / 255.0, blue: 252.0 / 255.0)),
                UIColor(ciColor: CIColor(red: 21.0 / 255.0, green: 126.0 / 255.0, blue: 252.0 / 255.0))],
                                                               gradientOrientation: .topRightBottomLeft)
        } else {
            invitationHolderView.isHidden = true
            invitationHolderView.isUserInteractionEnabled = false
        }
        
        membersTableView.reloadData()
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
        if presenter.wallet.multisigWallet!.amICreator {
            let storyBoard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
            let inviteCodeVC = storyBoard.instantiateViewController(withIdentifier: "inviteCodeVC") as! InviteCodeViewController
            inviteCodeVC.presenter.inviteCode = presenter.wallet.multisigWallet!.inviteCode
            present(inviteCodeVC, animated: true, completion: nil)
        }
    }
    
    func setMembersInfoHolderPosition() {
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
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(presenter.wallet.multisigWallet!.ownersCount)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberTVCReuseId")! as! MemberTableViewCell
        if (indexPath.item + 1) > presenter.wallet.multisigWallet!.owners.count {
            cell.fillWaitingMember()
        } else {
            let owner = presenter.wallet.multisigWallet!.owners[indexPath.item]
            let memberImage = PictureConstructor().createPicture(diameter: 34, seed: owner.address)
            cell.fillWithMember(address: owner.address, image: memberImage!, isCurrentUser: owner.associated.boolValue)
        }
        cell.hideSeparator = indexPath.item == (presenter.wallet.multisigWallet!.ownersCount - 1)
        
        return cell
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {

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
        setMembersInfoHolderPosition()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setMembersInfoHolderPosition()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Storyboard.waitingMembersSettingsVCSegueID {
            let waitingMembersSettingsVC = segue.destination as! WaitingMembersSettingsViewController
            waitingMembersSettingsVC.presenter.wallet = presenter.wallet
            waitingMembersSettingsVC.presenter.account = presenter.account!
        }
    }
    
    //MARK: Actions
    @IBAction func invitationCodeAction(_ sender: Any) {
        openShareInviteVC()
    }
    
    @IBAction func backAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "CreateMultiSig"
    }
}
