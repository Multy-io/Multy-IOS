//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDelegate = CurrencyToExchangeViewController
private typealias TableViewDataSource = CurrencyToExchangeViewController

class CurrencyToExchangeViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var presenter = CurrencyToExchangePresenter()
    var sendWalletDelegate: SendWalletProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presenter.mainVC = self
        registerCells()
        hideKeyboardWhenTappedAround()
        presenter.addFakeBlockchains()
        tableView.tableFooterView = UIView()
    }
    
    func registerCells() {
        let blockchainCell = UINib.init(nibName: "BlockchainCellTableViewCell", bundle: nil)
        tableView.register(blockchainCell, forCellReuseIdentifier: "blockchainCell")
    }
    
    
    @IBAction func backAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
}

extension TableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2 //numberOfPairs from backend response
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let blockchainCell = self.tableView.dequeueReusableCell(withIdentifier: "blockchainCell") as! BlockchainCellTableViewCell
        blockchainCell.fillFromArr(curObj: presenter.availableBlockchainArray[indexPath.row])
        blockchainCell.updateIconsVisibility(isAvailable: true, isChecked: false)
        blockchainCell.selectionStyle = .none
        return blockchainCell
    }
}

extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.checkForExistingWallet(index: indexPath.row)
    }
}
