//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import UICircularProgressRing
import Hash2Pics

private typealias LocalizeDelegate = WaitingMembersViewController
private typealias ScrollViewDelegate = WaitingMembersViewController

class WaitingMembersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AnalyticsProtocol {
    
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
    
    var tablesHolderTopEdge: CGFloat {
        return contentHeight - (headerView.frame.origin.y + headerView.frame.size.height)
    }
    
    var tablesHolderBottomEdge: CGFloat = 0 {
        didSet {
            if oldValue != tablesHolderBottomEdge {
                tableHolderViewHeight = tablesHolderBottomEdge
            }
        }
    }
    
    var tablesHolderFlipEdge: CGFloat {
        return contentHeight - (tablesHolderTopEdge - tablesHolderBottomEdge) / 2
    }
    
    var contentHeight : CGFloat {
        return self.contentView.frame.size.height
    }
    
    var tableHolderViewHeight : CGFloat = 0 {
        didSet {
            if oldValue != tableHolderViewHeight {
                
                
                membersInfoHolderViewHeightConstraint.constant = tableHolderViewHeight
                updateMembersCounterOpacity()
                self.view.layoutIfNeeded()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let panGR = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
//        membersInfoTouchpadView.addGestureRecognizer(panGR)
        registerCells()
        initialConfig()
        
        presenter.viewController = self
        presenter.viewControllerViewDidLoad()
        sendAnalyticsEvent(screenName: screenWaitingMembers, eventName: screenWaitingMembers)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tablesHolderBottomEdge = contentHeight - (membersCounterHolderView.frame.origin.y + membersCounterHolderView.frame.size.height + 40)
        
        presenter.viewControllerViewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        updateUI()
        
        presenter.viewControllerViewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        presenter.viewControllerViewWillDisappear()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
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
        
        if joinedCount == totalCount {
            if presenter.wallet.multisigWallet!.deployStatus.intValue == DeployStatus.pending.rawValue {
                presenter.bottomButtonStatus = .hidden
                stateImageView.image = UIImage(named: "pendingSmallClock")
                stateLabel.text = localize(string: Constants.pendingString)
            } else if presenter.wallet.multisigWallet!.deployStatus.intValue == DeployStatus.rejected.rawValue {
                //FIXME: add code
                presenter.bottomButtonStatus = .hidden
                stateImageView.image = UIImage(named: "pendingSmallClock")
                stateLabel.text = localize(string: Constants.pendingString)
            } else if presenter.wallet.multisigWallet!.deployStatus.intValue == DeployStatus.ready.rawValue {
                presenter.bottomButtonStatus = .paymentRequired
                stateImageView.image = UIImage(named: "readyToStart")
                stateLabel.text = localize(string: Constants.readyToStartString)
            } else {
                //FIXME: add code
                presenter.bottomButtonStatus = .hidden
                stateImageView.image = UIImage(named: "pendingSmallClock")
                stateLabel.text = localize(string: Constants.pendingString)
            }
            
            stateLabel.textColor = #colorLiteral(red: 0.8117647059, green: 1, blue: 0.8666666667, alpha: 1)
            
            //FIXME: price
//            backgroundView.backgroundColor = #colorLiteral(red: 0.3725490196, green: 0.8, blue: 0.4901960784, alpha: 1)
            backgroundView.applyOrUpdateGradient(withColours: [
                UIColor(ciColor: CIColor(red: 95.0 / 255.0, green: 204.0 / 255.0, blue: 125.0 / 255.0)),
                UIColor(ciColor: CIColor(red: 95.0 / 255.0, green: 204.0 / 255.0, blue: 125.0 / 255.0))],
                                                               gradientOrientation: .topRightBottomLeft)
            qrCodeImageView.isHidden = true
            
            
        } else {
            presenter.bottomButtonStatus = .inviteCode
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
            
            if presenter.wallet.multisigWallet!.deployStatus.intValue == DeployStatus.ready.rawValue {
                presenter.getEstimationInfo { [unowned self] in
                    switch $0 {
                    case .success(_):
                        self.setupBtnTitle()
                        break
                    case .failure(_):
                        break
                    }
                    
                    self.changeUI()
                }
            } else {
                changeUI()
            }
        } else {
            presenter.bottomButtonStatus = .hidden
            invitationHolderView.isHidden = true
            invitationHolderView.isUserInteractionEnabled = false
            
            changeUI()
        }
        
        invitationHolderView.isHidden = (presenter.bottomButtonStatus == .hidden)
    }
    
    func setupBtnTitle() {
        if self.presenter.estimationInfo     != nil {
            let priceInWei = self.presenter.estimationInfo!["priceOfCreation"] as! NSNumber
            let totalPrice = BigInt("\(priceInWei)") + self.presenter.feeAmount
            let priceString = totalPrice.cryptoValueString(for: self.presenter.wallet.blockchain)
            self.invitationCodeButton.setTitle("\(Constants.startForString) \(priceString) ETH", for: .normal)
        }
    }
    
    func changeUI() {
        membersTableView.reloadData()
        contentView.layoutIfNeeded()
    }
    
    func updateMembersCounterOpacity() {
        let rangeRaw = tablesHolderTopEdge - tablesHolderBottomEdge
        var value = tableHolderViewHeight
        if value < tablesHolderBottomEdge {
            value = tablesHolderBottomEdge
        }
        if value > tablesHolderTopEdge {
            value = tablesHolderTopEdge
        }
        
        membersCounterHolderView.alpha = 1 - (value - tablesHolderBottomEdge) / rangeRaw
    }
    
    func openShareInviteVC() {
        if presenter.wallet.multisigWallet!.amICreator {
            let storyBoard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
            let inviteCodeVC = storyBoard.instantiateViewController(withIdentifier: "inviteCodeVC") as! InviteCodeViewController
            inviteCodeVC.presenter.inviteCode = presenter.wallet.multisigWallet!.inviteCode
            present(inviteCodeVC, animated: true, completion: nil)
        }
    }
    
    func payForMultiSig() {
        presenter.payForMultiSig()
    }
    
    func setTableHolderPosition() {
        var tableHolderViewHeight = self.tableHolderViewHeight
        if tableHolderViewHeight < tablesHolderBottomEdge {
            tableHolderViewHeight = tablesHolderBottomEdge
        } else {
            if tableHolderViewHeight > tablesHolderFlipEdge {
                tableHolderViewHeight = tablesHolderTopEdge
            } else {
                tableHolderViewHeight = tablesHolderBottomEdge
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.tableHolderViewHeight = tableHolderViewHeight
        }
    }
    
    func updateWalletsAfterDragging() {
        setTableHolderPosition()
    }
    
    func setInitialTableHolderPosition() {
        UIView.animate(withDuration: 0.3, animations: {
            self.tableHolderViewHeight = self.tablesHolderBottomEdge
        })
    }
    
    //MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.wallet.multisigWallet!.ownersCount
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
    
    @IBAction func titleAction(_ sender: Any) {
        if tableHolderViewHeight == tablesHolderTopEdge {
            setInitialTableHolderPosition()
        }
    }
    
    //MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64.0
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        var result = false
        if presenter.wallet.multisigWallet!.amICreator {
            if indexPath.item < presenter.wallet.multisigWallet!.owners.count {
                let owner = presenter.wallet.multisigWallet!.owners[indexPath.item]
                result = owner.associated.boolValue ? false : true
            }
        }
        
        return result    
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {

        if editingStyle == .delete {
            presenter.kickOwnerWithIndex(index: indexPath.item)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.Storyboard.waitingMembersSettingsVCSegueID {
            let waitingMembersSettingsVC = segue.destination as! WaitingMembersSettingsViewController
            waitingMembersSettingsVC.presenter.wallet = presenter.wallet
            waitingMembersSettingsVC.presenter.account = presenter.account!
        }
    }
    
    func openNewlyCreatedWallet() {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let walletVC = storyboard.instantiateViewController(withIdentifier: "newWallet") as! WalletViewController
        walletVC.presenter.wallet = presenter.wallet
        walletVC.presenter.account = presenter.account
        
        navigationController?.pushViewController(walletVC, animated: true)
    }
    
    //MARK: Actions
    @IBAction func bottomButtonAction(_ sender: Any) {
        if presenter.bottomButtonStatus == .inviteCode {
            openShareInviteVC()
            sendAnalyticsEvent(screenName: screenWaitingMembers, eventName: inviteCodeTap)
        } else {
            payForMultiSig()
            sendAnalyticsEvent(screenName: screenWaitingMembers, eventName: payToStartTap)
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}
    
extension ScrollViewDelegate: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var tableHolderViewHeight = self.tableHolderViewHeight
        
        if tableHolderViewHeight < tablesHolderTopEdge {
            if tableHolderViewHeight < tablesHolderBottomEdge {
                if scrollView.contentOffset.y < 0 {
                    tableHolderViewHeight += scrollView.contentOffset.y / 3
                } else {
                    tableHolderViewHeight += scrollView.contentOffset.y
                }
            } else {
                tableHolderViewHeight += scrollView.contentOffset.y
                tableHolderViewHeight = tableHolderViewHeight > tablesHolderTopEdge ? tablesHolderTopEdge : tableHolderViewHeight
            }
            
            if !scrollView.isDecelerating || scrollView.contentOffset.y > 0 {
                scrollView.setContentOffset(CGPoint.zero, animated: false)
            }
        } else {
            if scrollView.contentOffset.y < 0 {
                tableHolderViewHeight += scrollView.contentOffset.y
            }
        }
        
        self.tableHolderViewHeight = tableHolderViewHeight
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if tableHolderViewHeight < tablesHolderBottomEdge - 40 {
            updateWalletsAfterDragging()
        } else {
            if !scrollView.isDecelerating {
                setTableHolderPosition()
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setTableHolderPosition()
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "CreateMultiSig"
    }
}
