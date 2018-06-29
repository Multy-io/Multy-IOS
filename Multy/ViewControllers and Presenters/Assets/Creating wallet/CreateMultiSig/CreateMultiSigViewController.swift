//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDataSource = CreateMultiSigViewController
private typealias TableViewDelegate = CreateMultiSigViewController

class CreateMultiSigViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    func openMembersVC() {
        let storyboard = UIStoryboard(name: "CreateMultiSigWallet", bundle: nil)
        let membersVC = storyboard.instantiateViewController(withIdentifier: "membersCountVC")
        membersVC.modalPresentationStyle = .overCurrentContext
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
        return UITableViewCell()
    }
}

extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 1 {
            openMembersVC()
        } else if indexPath.row == 2 {
            openMembersVC()
        }
    }
}


