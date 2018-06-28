//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias PickerDelegate = AddAddressViewController

class AddAddressViewController: UIViewController {
    @IBOutlet weak var addressTF: UITextField!
    @IBOutlet weak var blockchainPickerView: UIPickerView!
    
    let presenter = AddAddressPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.mainVC = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func okAction(_ sender: UIButton) {
        
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        
    }
}

extension PickerDelegate: UIPickerViewDelegate {
    
}

extension PickerDelegate: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return presenter.blockchainData.count
    }
}
