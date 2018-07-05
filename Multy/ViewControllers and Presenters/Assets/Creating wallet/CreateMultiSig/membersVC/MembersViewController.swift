//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDelegate = MembersViewController
private typealias TableViewDataSource = MembersViewController

class MembersViewController: UIViewController {

    @IBOutlet weak var clearView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    
    var countOfDelegate: CountOfProtocol?
    
    let presenter = MembersPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        closeVcByTap()
        
        
        presenter.mainVC = self
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissMe))
        clearView.addGestureRecognizer(tap)
        headerView.roundCorners(corners: [.topLeft, .topRight], radius: 12)
        if screenHeight == heightOfX {
            tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 34, right: 0)
            tableBottomConstraint.constant = -34
        }
    }
    
    @objc func dismissMe() {
        self.dismiss(animated: true, completion: nil)
    }

}

extension TableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 16)
        cell.textLabel?.text = "\(indexPath.row + 2)" + " members"
        return cell
    }
}

extension TableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tag = presenter.isMembers == true ? "members" : "signs"
        countOfDelegate?.countSomething(tag: tag, count: indexPath.row + 2) // dont have 0 or 1
        tableView.deselectRow(at: indexPath, animated: true)
        dismiss(animated: true, completion: nil)
    }
}
