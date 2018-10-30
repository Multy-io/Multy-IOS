//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit
import ZFRippleButton

private typealias LocalizeDelegate = SendAmountViewController

class SendAmountViewController: UIViewController, UITextFieldDelegate, AnalyticsProtocol {
    @IBOutlet weak var titleLbl: UILabel! 
    @IBOutlet weak var amountTF: UITextField!
    @IBOutlet weak var topSumLbl: UILabel!
    @IBOutlet weak var topCurrencyNameLbl: UILabel!
    @IBOutlet weak var bottomSumLbl: UILabel!
    @IBOutlet weak var bottomCurrencyLbl: UILabel!
    @IBOutlet weak var spendableSumAndCurrencyLbl: UILabel!
    @IBOutlet weak var nextBtn: ZFRippleButton!
    @IBOutlet weak var maxBtn: UIButton!
    @IBOutlet weak var maxLbl: UILabel!
    @IBOutlet weak var btnSumLbl: UILabel!
    @IBOutlet weak var commissionSwitch: UISwitch!
    @IBOutlet weak var commissionStack: UIStackView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var swapBtn: UIButton!
    
    @IBOutlet weak var constraintNextBtnBottom: NSLayoutConstraint!
    @IBOutlet weak var constratintNextBtnHeight: NSLayoutConstraint!
    @IBOutlet weak var constraintForTitletoBtn: NSLayoutConstraint!
    @IBOutlet weak var constraintSpendableViewBottom: NSLayoutConstraint!
    @IBOutlet weak var constraintTop: NSLayoutConstraint!
    
    let presenter = SendAmountPresenter()
    let numberFormatter = NumberFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        presenter.vc = self
        presenter.vcViewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        presenter.vcViewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presenter.vcViewWillAppear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        presenter.vcViewDidDisappear()
    }
    
    func configure() {
        enableSwipeToBack()
        numberFormatter.numberStyle = .decimal
    }
    
    func updateUI() {
        if presenter.transactionDTO.choosenWallet!.isMultiSig {
            commissionStack.isHidden = true
            commissionSwitch.isOn = false
        }
        
        topCurrencyNameLbl.text = " " + presenter.cryptoName
        
        if presenter.sumInCrypto > Int64(0) && presenter.blockchain != nil {
            let cryptoValue = presenter.sumInCrypto.cryptoValueString(for: presenter.blockchain!)
            amountTF.text = cryptoValue
            topSumLbl.text = cryptoValue
            btnSumLbl.text = cryptoValue
        }
    }
    
    @IBAction func cancelAction(_ sender: Any) {
        
    }
    
    @IBAction func payForCommisionAction(_ sender: Any) {
        
    }
    
    @IBAction func changeAction(_ sender: Any) {
        
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Sends"
    }
}
