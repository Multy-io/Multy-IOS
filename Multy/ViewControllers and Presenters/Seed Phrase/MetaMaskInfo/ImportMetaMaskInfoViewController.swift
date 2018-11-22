//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import ZFRippleButton

class ImportMetaMaskInfoViewController: UIViewController {

    @IBOutlet weak var continueBtn: ZFRippleButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.continueBtn.applyGradient(withColours: [UIColor(ciColor: CIColor(red: 0/255, green: 178/255, blue: 255/255)),
                                                     UIColor(ciColor: CIColor(red: 0/255, green: 122/255, blue: 255/255))],
                                       gradientOrientation: .horizontal)
    }
    
    @IBAction func continueAction(_ sender: Any) {
        let checkWordsVC = viewControllerFrom("SeedPhrase", "backupSeed") as! CheckWordsViewController
        checkWordsVC.isRestore = true
        checkWordsVC.presenter.accountType = .metamask
        navigationController?.pushViewController(checkWordsVC, animated: true)
    }
    
    @IBAction func closeBtn(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func closeBtnAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}
