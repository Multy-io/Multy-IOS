//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDataSource = EOSAccountsViewController
private typealias TableViewDelegate = EOSAccountsViewController

class EOSAccountsViewController: UIViewController {
    let presenter = EOSAccountsPresenter()
    
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var accountsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.viewController = self
        presenter.presentedViewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.presentedViewWillAppear()
    }
    
    fileprivate func registerCells() {
        let nib = UINib(nibName: "EOSAccountTableViewCell", bundle: nil)
        accountsTableView.register(nib, forCellReuseIdentifier: "EOSAccountReuseID")
    }
    
    //MARK: Actions
    @IBAction func okAction(_ sender: Any) {
        
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        
    }
}

extension TableViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EOSAccountReuseID") as! EOSAccountTableViewCell
        //FIXME: For test only
        cell.fill(name: "name")
        
        return cell
    }
}

extension TableViewDelegate: UITableViewDelegate {
    
}
