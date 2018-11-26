//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = SeedPhraseWordPresenter

class SeedPhraseWordPresenter: NSObject {
    var mainVC : SeedPhraseWordViewController?
    var countOfTaps = -1
    var accountType = DataManager.shared.accountType
    var lastScreenposition = DataManager.shared.accountType.seedPhraseScreens - 1
    var mnemonicPhraseArray = [String]() {
        didSet {
            if mnemonicPhraseArray.count > 0 && DataManager.shared.realmManager.account?.seedPhrase != ""/*&& mainVC?.isNeedToBackup == nil*/ {
                let mnemonicString = mnemonicPhraseArray.joined(separator: " ")
                DataManager.shared.realmManager.writeSeedPhrase(mnemonicString, completion: { (error) in
                    if let err = error {
                        print(err.localizedDescription)
                    } else {
                        print("seed phrase wrote down")
                    }
                })
            }
        }
    }
    
    func getSeedFromAcc() {
//        mnemonicPhraseArray = DataManager.shared.getMnenonicArray()
        DataManager.shared.getAccount { (acc, err) in
            if acc!.seedPhrase.isEmpty == false {
                self.mnemonicPhraseArray = (acc?.seedPhrase.components(separatedBy: " "))!
            } else {
                self.mnemonicPhraseArray = (acc?.backupSeedPhrase.components(separatedBy: " "))!
            }
        }
    }
    
    func presentNextTripleOrContinue() {
        self.countOfTaps += 1
        
        if self.countOfTaps == lastScreenposition - 1 {
            self.mainVC?.nextWordBtn.setTitle(localize(string: Constants.continueString), for: .normal)
        }
        
//        if DataManager.shared.restoreAccountType == .metamask {
            mainVC?.bricksView.isHidden = false
            mainVC?.bricksView.subviews.forEach{ $0.removeFromSuperview() }

//            if self.countOfTaps == 0 {
                mainVC!.bricksView.addSubview(BricksView(with: mainVC!.bricksView.bounds, accountType: accountType, color: brickColorSelectedBlue, and: 3 * (countOfTaps + 1)))
//            } else if self.countOfTaps == 1 {
//                mainVC!.bricksView.addSubview(BricksView(with: mainVC!.bricksView.bounds, and: 9, color: brickColorSelectedBlue))
//            } else if self.countOfTaps == 2 {
//                mainVC!.bricksView.addSubview(BricksView(with: mainVC!.bricksView.bounds, and: 12, color: brickColorSelectedBlue))
//            } else
//                if self.countOfTaps == lastScreenposition - 1 {
//                    self.mainVC?.nextWordBtn.setTitle(localize(string: Constants.continueString), for: .normal)
//                    self.mainVC?.blocksImage.image = #imageLiteral(resourceName: "05")
//            }
            
//        } else if DataManager.shared.restoreAccountType == .multy || DataManager.shared.restoreAccountType == nil {
//            mainVC?.bricksView.isHidden = true
//            if self.countOfTaps == 0 {
//                self.mainVC?.blocksImage.image = #imageLiteral(resourceName: "02")
//            } else if self.countOfTaps == 1 {
//                self.mainVC?.blocksImage.image = #imageLiteral(resourceName: "03")
//            } else if self.countOfTaps == 2 {
//                self.mainVC?.blocksImage.image = #imageLiteral(resourceName: "04")
//            } else
//                if self.countOfTaps == lastScreenposition - 1 {
//                    self.mainVC?.nextWordBtn.setTitle(localize(string: Constants.continueString), for: .normal)
//                    self.mainVC?.blocksImage.image = #imageLiteral(resourceName: "05")
//            }
//        }
        
        
        //getNextWords
        if self.countOfTaps < lastScreenposition {
            self.mainVC?.topWordLbl.text = mnemonicPhraseArray[3 * countOfTaps]
            self.mainVC?.mediumWordLbl.text = mnemonicPhraseArray[3 * countOfTaps + 1]
            self.mainVC?.bottomWord.text = mnemonicPhraseArray[3 * countOfTaps + 2]
        }  else {
            if self.mainVC!.whereFrom != nil && self.mainVC!.isNeedToBackup == nil {
                self.mainVC!.navigationController?.popToViewController(self.mainVC!.whereFrom!, animated: true)
                return
            }
            self.mainVC?.performSegue(withIdentifier: "backupSeedPhraseVC", sender: UIButton.self)
        }
    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Seed"
    }
}
