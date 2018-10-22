//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import Hash2Pics

private typealias TableViewDelegate = MSWalletSettingsViewController
private typealias TableViewDataSource = MSWalletSettingsViewController

class MSWalletSettingsViewController: UIViewController {

    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var signsCountLbl: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    
    let presenter = MSWalletSettingsPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func setupUI() {
        let memberCell = UINib.init(nibName: "MemberTableViewCell", bundle: nil)
        tableView.register(memberCell, forCellReuseIdentifier: "memberTVCReuseId")
        
        tableHeightConstraint.constant = CGFloat(64 * presenter.wallet!.multisigWallet!.ownersCount)
        nameTF.text = presenter.wallet!.name
        signsCountLbl.text = "\(presenter.wallet!.multisigWallet!.signaturesRequiredCount)"
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func chooseCurrencyAction(_ sender: Any) {
        self.goToCurrency()
    }
    
    func goToCurrency() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let currencyVC = storyboard.instantiateViewController(withIdentifier: "currencyVC")
        self.navigationController?.pushViewController(currencyVC, animated: true)
    }
    
    func openWallet() {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let walletVC = storyboard.instantiateViewController(withIdentifier: "newWallet") as! WalletViewController
        walletVC.presenter.wallet = presenter.wallet
        walletVC.presenter.account = presenter.acc
//        navigationController?.popToRootViewController(animated: true)
        navigationController?.pushViewController(walletVC, animated: true)
    }
    
    func openAddressVC(address: String) {
        let storyboard = UIStoryboard(name: "Wallet", bundle: nil)
        let adressVC = storyboard.instantiateViewController(withIdentifier: "walletAdressVC") as! AddressViewController
        adressVC.modalPresentationStyle = .overCurrentContext
        adressVC.modalTransitionStyle = .crossDissolve
        adressVC.addressString = address
        adressVC.wallet = presenter.wallet
        present(adressVC, animated: true, completion: nil)
    }

}


extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
}

extension TableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.wallet!.multisigWallet!.ownersCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "memberTVCReuseId")! as! MemberTableViewCell
        
        let owner = presenter.wallet!.multisigWallet!.owners[indexPath.row]
        let memberImage = PictureConstructor().createPicture(diameter: 34, seed: owner.address)
        cell.fillWithMember(address: owner.address, image: memberImage!, isCurrentUser: owner.associated.boolValue)
        
        cell.hideSeparator = indexPath.item == (presenter.wallet!.multisigWallet!.ownersCount - 1)
//        cell.isUserInteractionEnabled = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if presenter.wallet!.multisigWallet!.owners[indexPath.row].associated.boolValue == true {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Open Wallet", style: .default, handler: { (action) in
                self.openWallet()
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Open Address", style: .default, handler: { (action) in
                self.openAddressVC(address: self.presenter.wallet!.multisigWallet!.owners[indexPath.row].address)
            }))
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(actionSheet, animated: true, completion: nil)
        } else {
            openAddressVC(address: self.presenter.wallet!.multisigWallet!.owners[indexPath.row].address)
        }
    }
}
