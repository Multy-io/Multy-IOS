//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDelegate = ContactViewController
private typealias TableViewDataSource = ContactViewController

class ContactViewController: UIViewController {

    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactImageLabel: UILabel!
    @IBOutlet weak var contactAddressesTableView: UITableView!
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var noAddressesLabel: UILabel!
    @IBOutlet weak var savedAddressesLabel: UILabel!
    
    var presenter = ContactPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.mainVC = self
        presenter.roundContactImage()
        presenter.fillContactImage()
        contactName.text = presenter.contact!.displayName()
        
        if presenter.contact?.addresses.count == 0 {
            noAddressesLabel.isHidden = false
            savedAddressesLabel.isHidden = true
        }
        
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
}

extension TableViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.contact?.addresses.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "Cell")
        
        presenter.fillCell(cell, at: indexPath)
        
        return cell
    }
}
