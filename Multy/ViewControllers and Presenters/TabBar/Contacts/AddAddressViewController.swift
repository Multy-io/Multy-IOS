//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias PickerDelegate = AddAddressViewController
private typealias TextFieldDelegate = AddAddressViewController
private typealias LocalizableDelegate = AddAddressViewController

class AddAddressViewController: UIViewController {
    @IBOutlet weak var addressTF: UITextField!
    @IBOutlet weak var blockchainPickerView: UIPickerView!
    @IBOutlet weak var whiteView: UIView!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    let presenter = AddAddressPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        presenter.mainVC = self
        blockchainPickerView.showsSelectionIndicator = false
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        self.view.addGestureRecognizer(tap)
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        if addressTF.isFirstResponder {
            addressTF.resignFirstResponder()
        } else {
            let touchPoint = sender.location(in: whiteView)
            if whiteView.bounds.contains(touchPoint) == false {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func okAction(_ sender: UIButton) {
        guard addressTF.text != nil && !addressTF.text!.isEmpty else {
            shakeView(viewForShake: addressTF)
            
            return
        }
        
        let address = addressTF.text!
        let selectedBlockchainType = presenter.blockchainData[blockchainPickerView.selectedRow(inComponent: 0)]
        let isAddressAcceptable = DataManager.shared.isAddressValid(address, for: selectedBlockchainType).isValid
        
        if DataManager.shared.isAddressSaved(address) {
            presentAlert(with: localize(string: Constants.savedAddressString))
        } else if isAddressAcceptable {
            presenter.delegate?.passNewAddress(address, andBlockchainType: selectedBlockchainType)
            dismiss(animated: true, completion: nil)
        } else {
            presentAlert(with: localize(string: Constants.addressNotMatchString))
        }
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension PickerDelegate: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 45
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let size = CGFloat(35.0)
        let xCoordinate = -size
        let myView = UIView(frame: CGRect(x: xCoordinate, y: 0, width: size, height: size))
        let myImageView = UIImageView(frame: CGRect(x: xCoordinate, y: 0, width: size, height: size))
        
        let rowString = presenter.blockchainData[row].fullName
        
        myImageView.image = UIImage(named: presenter.blockchainData[row].iconString)
        myImageView.contentMode = .scaleAspectFill
        
        let myLabel = UILabel(frame: CGRect(x: xCoordinate + size + 10, y:0, width: pickerView.bounds.width - size * 2, height: size + 10))
        myLabel.font = UIFont(name:"Avenir Next Demi Bold", size: 18)
        myLabel.text = rowString
        
        myView.addSubview(myLabel)
        myView.addSubview(myImageView)
        
        return myView
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return presenter.blockchainData[row].fullName
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
//        print("pickerView selected: %i", row)
    }
}

extension PickerDelegate: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerView.subviews.forEach{ $0.isHidden = $0.frame.height < 1.0 }
        
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return presenter.blockchainData.count
    }
}

extension TextFieldDelegate: UITextFieldDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.contains(UIPasteboard.general.string ?? "") {
            return false
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        blockchainPickerView.isUserInteractionEnabled = false
        okButton.isUserInteractionEnabled = false
        cancelButton.isUserInteractionEnabled = false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        blockchainPickerView.isUserInteractionEnabled = true
        okButton.isUserInteractionEnabled = true
        cancelButton.isUserInteractionEnabled = true
    }
}

extension LocalizableDelegate: Localizable {
    var tableName: String {
        return "Contacts"
    }
    
    
}
