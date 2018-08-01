//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDataSource = EOSAccountsViewController
private typealias TableViewDelegate = EOSAccountsViewController

class EOSAccountsViewController: UIViewController {
    let presenter = EOSAccountsPresenter()
    
    @IBOutlet weak var accountsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.presentedViewWillAppear()
    }
    
    func setupUI() {
        presenter.viewController = self
        presenter.presentedViewDidLoad()
        registerCells()
    }
    
    fileprivate func registerCells() {
        let nib = UINib(nibName: "EOSAccountTableViewCell", bundle: nil)
        accountsTableView.register(nib, forCellReuseIdentifier: "EOSAccountReuseID")
    }
    
    //MARK: Actions
    @IBAction func okAction(_ sender: Any) {
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        navigationController?.popToRootViewController(animated: true)
    }
}

extension TableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.namesArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = accountsTableView.dequeueReusableCell(withIdentifier: "EOSAccountReuseID") as! EOSAccountTableViewCell
        //FIXME: For test only
        cell.fill(name: presenter.namesArr[indexPath.row])
        
        return cell
    }
}

extension TableViewDelegate: UITableViewDelegate {
    
}
