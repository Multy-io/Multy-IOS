//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDelegate = ContactViewController
private typealias TableViewDataSourceDelegate = ContactViewController
private typealias LocalizeDelegate = ContactsViewController

class ContactViewController: UIViewController {

    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactImageLabel: UILabel!
    @IBOutlet weak var contactAddressesTableView: UITableView!
    @IBOutlet weak var contactName: UILabel!
    @IBOutlet weak var noAddressesLabel: UILabel!
    @IBOutlet weak var savedAddressesLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var floatingView: UIView!
    @IBOutlet weak var addNewBtn: UIButton!
    
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
        
        floatingView.layer.cornerRadius = floatingView.frame.width / 2
        addNewBtn.makeBlueGradient()
        
        (self.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    @IBAction func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deleteAction() {
        let alert = UIAlertController(title: presenter.localize(string: Constants.warningString),
                                      message: presenter.localize(string: Constants.areYouSureString),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [unowned self] (_) in
            self.view.isUserInteractionEnabled = false
            self.presenter.deleteContact()
        }))
        alert.addAction(UIAlertAction(title: presenter.localize(string: Constants.cancelString), style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func addAddressAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let addAddressVC = storyboard.instantiateViewController(withIdentifier: "addAdressStoryboardID") as! AddAddressViewController
        addAddressVC.modalPresentationStyle = .overCurrentContext
        addAddressVC.modalTransitionStyle = .crossDissolve
        addAddressVC.presenter.delegate = presenter
        present(addAddressVC, animated: true, completion: nil)
        //        sendAnalyticsEvent(screenName: "\(screenWalletWithChain)\(wallet!.chain)", eventName: "\(addressWithChainTap)\(wallet!.chain)")
    }
}

extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter.tappedCell(at: indexPath)
    }
}

extension TableViewDataSourceDelegate: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presenter.contact?.addresses.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addressCellID", for: indexPath) as! ContactCell
        cell.selectionStyle = .none
        
        presenter.fillCell(cell, at: indexPath)
        
        return cell
    }
}
