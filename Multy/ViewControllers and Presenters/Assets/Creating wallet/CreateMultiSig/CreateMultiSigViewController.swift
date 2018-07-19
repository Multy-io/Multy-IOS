//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import ZFRippleButton

private typealias TableViewDataSource = CreateMultiSigViewController
private typealias TableViewDelegate = CreateMultiSigViewController
private typealias TextFieldDelegate  = CreateMultiSigViewController
private typealias LocalizeDelegate = CreateMultiSigViewController
private typealias SendWalletDelegate = CreateMultiSigViewController
private typealias ChooseBlockchainDelegate = CreateMultiSigViewController

class CreateMultiSigViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var createBtn: ZFRippleButton!
    let loader = PreloaderView(frame: HUDFrame, text: "Creating Wallet...", image: #imageLiteral(resourceName: "walletHuge"))
    
    @IBOutlet weak var selectWalletLabel: UILabel!
    @IBOutlet weak var linkedWalletNameLabel: UILabel!
    @IBOutlet weak var linkedWalletImageView: UIImageView!
    @IBOutlet weak var linkedWalletStackView: UIStackView!
    @IBOutlet weak var linkedWalletAddressLabel: UILabel!
    
    let presenter = CreateMultiSigPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.mainVC = self
        hideKeyboardWhenTappedAround()
        swipeToBack()
        tableView.tableFooterView = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        (self.tabBarController as! CustomTabBarViewController).menuButton.isHidden = true
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        
        if let linkedWallet = presenter.choosenWallet {
            selectWalletLabel.isHidden = true
            linkedWalletStackView.isHidden = false
            linkedWalletImageView.image = UIImage(named: linkedWallet.blockchainType.iconString)
            linkedWalletNameLabel.text = linkedWallet.name
            linkedWalletAddressLabel.text = linkedWallet.address
        } else {
            linkedWalletStackView.isHidden = true
            selectWalletLabel.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let nameCell = tableView.cellForRow(at: [0, 0]) as! CreateWalletNameTableViewCell
        if let name = nameCell.walletNameTF.text, name.isEmpty {
            nameCell.walletNameTF.becomeFirstResponder()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        tableView.resignFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        createBtn.applyGradient(withColours: [UIColor(ciColor: CIColor(red: 0/255, green: 178/255, blue: 255/255)),
                                              UIColor(ciColor: CIColor(red: 0/255, green: 122/255, blue: 255/255))],
                        gradientOrientation: .horizontal)
    }
    
    fileprivate func openMembersVC() {
        let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
        let membersVC = storyboard.instantiateViewController(withIdentifier: "membersCountVC") as! MembersViewController
        membersVC.modalPresentationStyle = .overCurrentContext
        membersVC.countOfDelegate = presenter
        membersVC.presenter.membersCount = presenter.membersCount
        membersVC.presenter.signaturesCount = presenter.signaturesCount
        self.present(membersVC, animated: true, completion: nil)
    }
    
    fileprivate func chooseBlockchain() {
                /*
                     let storyboard = UIStoryboard(name: "Main", bundle: nil)
                     let chainsVC = storyboard.instantiateViewController(withIdentifier: "chainsVC") as! BlockchainsViewController
            
                     chainsVC.presenter.selectedBlockchain = presenter.selectedBlockchainType
                     chainsVC.delegate = self
             
                     self.navigationController?.pushViewController(chainsVC, animated: true)
             
                     updateBlockchainCell(blockchainCell: nil)
              */
            }
    
        fileprivate func updateBlockchainCell(blockchainCell: CreateWalletBlockchainTableViewCell?) {
                /*
                     let cell = blockchainCell == nil ? self.tableView.dequeueReusableCell(withIdentifier: "blockchainCell") as! CreateWalletBlockchainTableViewCell : blockchainCell!
                     cell.blockchainLabel.text = presenter.selectedBlockchainType.combinedName
             
                     if presenter.selectedBlockchainType.isMainnet == false {
                         cell.blockchainLabel.text! += "  Testnet"
                     }
             
                     if blockchainCell == nil {
                         tableView.reloadRows(at: [[0, 2]], with: .none)
                     }
              */
            }
    

    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createAction(_ sender: Any) {
        if presenter.walletName.isEmpty {
            presentAlert(with: localize(string: Constants.walletNameAlertString))
            
            return
        }
        
        if presenter.choosenWallet == nil {
            presentAlert(with: localize(string: Constants.chooseWalletString))
            
            return
        }
        
        let storyBoard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
        let waitingMembersVC = storyBoard.instantiateViewController(withIdentifier: "waitingMembers") as! WaitingMembersViewController
        waitingMembersVC.presenter.membersAmount = presenter.membersCount
        //FIXME:
        let nameCell = self.tableView.cellForRow(at: IndexPath(item: 0, section: 0)) as! CreateWalletNameTableViewCell
        waitingMembersVC.presenter.walletName = nameCell.walletNameTF.text!
        navigationController?.pushViewController(waitingMembersVC, animated: true)
//        waitingMembersVC.openShareInviteVC()
    }
    
    func chooseAnotherWalletAction() {
        let storyboard = UIStoryboard(name: "Receive", bundle: nil)
        let walletsVC = storyboard.instantiateViewController(withIdentifier: "ReceiveStart") as! ReceiveStartViewController
        walletsVC.presenter.isNeedToPop = true
        walletsVC.presenter.displayedBlockchainOnly = presenter.selectedBlockchainType
        walletsVC.sendWalletDelegate = self
        walletsVC.titleTextKey = ""
        self.navigationController?.pushViewController(walletsVC, animated: true)
//        sendAnalyticsEvent(screenName: "\(screenReceiveSummaryWithChain)\(presenter.wallet!.chain)", eventName: changeWalletTap)
    }
    
    @IBAction func selectLinkedWalletAction(_ sender: Any) {
        chooseAnotherWalletAction()
    }
}

extension SendWalletDelegate: SendWalletProtocol {
    func sendWallet(wallet: UserWalletRLM) {
        presenter.choosenWallet = wallet
    }
}

extension TableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let nameCell = self.tableView.dequeueReusableCell(withIdentifier: "nameCell") as! CreateWalletNameTableViewCell
            
            return nameCell
        case 1:
            let signsCell = self.tableView.dequeueReusableCell(withIdentifier: "signsCell") as! CreateWalletBlockchainTableViewCell
            signsCell.setLblValue(value: "\(presenter.signaturesCount) of \(presenter.membersCount)")
            
            return signsCell
            
        case 2:
            let blockchainCell = self.tableView.dequeueReusableCell(withIdentifier: "blockchainCell") as! CreateWalletBlockchainTableViewCell
            let blockchainString = presenter.selectedBlockchainType.combinedName
            blockchainCell.setLblValue(value: blockchainString)
            
            return blockchainCell
            
        default:
            return UITableViewCell()
        }
    }
}

extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedRow = indexPath.row
        if selectedRow == 1 {
            openMembersVC()
        } else if selectedRow == 2 {
            chooseBlockchain()
        }
    }
}

extension TextFieldDelegate: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.dismissKeyboard()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (textField.text?.count)! + string.count < maxNameLength {
            return true
        } else {
            return false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text {
            presenter.walletName = text.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        }
    }
}

extension ChooseBlockchainDelegate: ChooseBlockchainProtocol {
    func setBlockchain(blockchain: BlockchainType) {
        presenter.selectedBlockchainType = blockchain
        updateBlockchainCell(blockchainCell: nil)    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}
