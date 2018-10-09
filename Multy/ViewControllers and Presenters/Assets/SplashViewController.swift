//Copyright 2017 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = SplashViewController

class SplashViewController: UIViewController {

    @IBOutlet weak var connectBtn: UIButton!
    
    var isJailAlert = 0
    var parentVC: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch isJailAlert {
        case 0:
            self.updateAlert()
        case 1:
            self.jailAlert()
        case 2:
            self.serverStopAlert()
        default: break
        }
    }
    
    func jailAlert() {
        let message = localize(string: Constants.jailbrokenDeviceWarningString)
        let alert = UIAlertController(title: localize(string: Constants.warningString), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            DataManager.shared.clearDB(completion: { (err) in
                exit(0)
            })
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateAlert() {
        let message = localize(string: Constants.updateMultyString)
        let alert = UIAlertController(title: localize(string: Constants.weHaveUpdateString), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: localize(string: Constants.goToUpdateString), style: .cancel, handler: { (action) in
            if let url = URL(string: "itms-apps://itunes.apple.com/us/app/multy-blockchain-wallet/id1328551769"),
                UIApplication.shared.canOpenURL(url){
                UIApplication.shared.openURL(url)
                exit(0)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func serverStopAlert() {
        connectBtn.isHidden = false
        view.alpha = 0.5
        (parentVC?.tabBarController as! CustomTabBarViewController).changeViewVisibility(isHidden: true)
        serverOffAlert()
    }
    
    func serverOffAlert() {
        let title = localize(string: Constants.serverNotWorkTitleString)
        let message = localize(string: Constants.serverNotWorkingMessageString)
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
            
        }))
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func connectAction(_ sender: Any) {
        DataManager.shared.getServerConfig { (soft, hard, err) in
            if soft != nil && hard != nil {
                self.dismissVC()
            } else {
                self.serverOffAlert()
            }
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Assets"
    }
}
