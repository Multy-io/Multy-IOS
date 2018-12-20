//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDelegate = CurrencyToExchangeViewController
private typealias TableViewDataSource = CurrencyToExchangeViewController
private typealias SearchBarDelegate = CurrencyToExchangeViewController

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
        presenter.addAssetsTypes()
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
        return presenter.filteredAssets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let blockchainCell = self.tableView.dequeueReusableCell(withIdentifier: "blockchainCell") as! BlockchainCellTableViewCell
        blockchainCell.fillFromArr(curObj: presenter.filteredAssets[indexPath.row])
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

extension SearchBarDelegate: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        presenter.filterAssets(by: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
