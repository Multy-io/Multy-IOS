//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDataSource = CreateMultiSigViewController
private typealias TableViewDelegate = CreateMultiSigViewController

class CreateMultiSigViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
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
    }
    
    func openMembersVC(isMembers: Bool) {
        let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
        let membersVC = storyboard.instantiateViewController(withIdentifier: "membersCountVC") as! MembersViewController
        membersVC.modalPresentationStyle = .overCurrentContext
        membersVC.countOfDelegate = presenter
        membersVC.presenter.isMembers = isMembers
        self.present(membersVC, animated: true, completion: nil)
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
        if indexPath.row == 0 {
            let nameCell = self.tableView.dequeueReusableCell(withIdentifier: "nameCell") as! CreateWalletNameTableViewCell
            nameCell.walletNameTF.becomeFirstResponder()
            
            return nameCell
        } else if indexPath.row == 1 {
            let membersCell = self.tableView.dequeueReusableCell(withIdentifier: "membersCell") as! CreateWalletBlockchainTableViewCell
            membersCell.setLblValue(value: "\(presenter.countOfMembers)")
            return membersCell
        } else if indexPath.row == 2 {
            let signsCell = self.tableView.dequeueReusableCell(withIdentifier: "signsCell") as! CreateWalletBlockchainTableViewCell
            signsCell.setLblValue(value: "\(presenter.countOfSigns)")
            return signsCell
        }
        return UITableViewCell()
    }
}

extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            openMembersVC(isMembers: true)
        } else if indexPath.row == 2 {
            openMembersVC(isMembers: false)
        }
    }
}


