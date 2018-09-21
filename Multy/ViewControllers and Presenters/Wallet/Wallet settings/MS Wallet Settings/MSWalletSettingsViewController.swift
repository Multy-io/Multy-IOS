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
        
        return cell
    }
}
