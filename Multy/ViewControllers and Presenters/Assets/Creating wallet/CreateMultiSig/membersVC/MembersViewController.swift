//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias TableViewDelegate = MembersViewController
private typealias TableViewDataSource = MembersViewController
private typealias PickerViewDataSource = MembersViewController
private typealias PickerViewDelegate = MembersViewController

fileprivate let countOffset = 2

class MembersViewController: UIViewController {

    @IBOutlet weak var clearView: UIView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var countsPicker: UIPickerView!
    var countOfDelegate: CountOfProtocol?
    
    let presenter = MembersPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        closeVcByTap()
        
        
        presenter.mainVC = self
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissMe))
        clearView.addGestureRecognizer(tap)
        if screenHeight == heightOfX {
            
        }
        
        countsPicker.selectRow(presenter.signaturesCount - countOffset + 1, inComponent: 0, animated: false)
        countsPicker.selectRow(presenter.membersCount - countOffset, inComponent: 1, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        headerView.roundCorners(corners: [.topLeft, .topRight], radius: 12)
    }
    
    @objc @IBAction func dismissMe() {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneAction() {
        let firstSectionCount = countOffset - 1 + countsPicker.selectedRow(inComponent: 0)
        let secondSectionCount = countOffset + countsPicker.selectedRow(inComponent: 1)
        countOfDelegate?.passMultiSigInfo(signaturesCount: firstSectionCount, membersCount: secondSectionCount)
        dismissMe()
    }
}

extension PickerViewDelegate: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if component == 1  {
            return "\(row + countOffset)"
        }
        return "\(row + countOffset - 1)"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            let secondSectionRow = pickerView.selectedRow(inComponent: 1)
            if row > secondSectionRow {
                pickerView.selectRow(row - 1, inComponent: 1, animated: true)
            }
        case 1:
            let firstSectionRow = pickerView.selectedRow(inComponent: 0)
            if firstSectionRow > row {
                pickerView.selectRow(row + 1, inComponent: 0, animated: true)
            }
        default:
            break
        }
    }
}

extension PickerViewDataSource: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        pickerView.subviews.forEach{ $0.isHidden = $0.frame.height < 1.0 }
        
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return 50
        } else {
            return 49
        }
    }
}
