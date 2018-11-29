//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import UIKit

private typealias LocalizeDelegate = CheckWordsPresenter

class CheckWordsPresenter: NSObject {
    
    var checkWordsVC: CheckWordsViewController?
    var phraseArr = [String]()
    var originalSeedPhrase = String()
    var accountType: AccountType = .multy {
        didSet {
            wordsCount = accountType.seedPhraseWordsCount
        }
    }
    var wordsCount = 15
    
    func isSeedPhraseFull() -> Bool {
        return phraseArr.count == wordsCount
    }
    
    func isSeedPhraseCorrect() -> Bool {
        return originalSeedPhrase.utf8CString == phraseArr.joined(separator: " ").utf8CString
    }
    
    func getSeedPhrase() {
        DataManager.shared.getSeedPhrase { (seedPhrase, error) in
            if let phrase = seedPhrase {
                self.originalSeedPhrase = phrase
            }
        }
    }
    
    func auth(seedString: String) {
        if !(ConnectionCheck.isConnectedToNetwork()) {
            if self.isKind(of: NoInternetConnectionViewController.self) || self.isKind(of: UIAlertController.self) {
                return
            }
            
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "NoConnectionVC") as! NoInternetConnectionViewController
            self.checkWordsVC!.present(nextViewController, animated: true, completion: nil)
            
            return
        }
        
        self.checkWordsVC?.view.isUserInteractionEnabled = false
        if let errString = DataManager.shared.getRootString(from: seedString).1 {
            let alert = UIAlertController(title: localize(string: Constants.warningString), message: localize(string: errString), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (action) in
                self.checkWordsVC?.navigationController?.popViewController(animated: true)
            }))
            self.checkWordsVC?.present(alert, animated: true, completion: nil)
            self.checkWordsVC?.performSegue(withIdentifier: "wrongVC", sender: (Any).self)
            
            return
        }
        
        checkWordsVC?.nextWordOrContinue.isEnabled = false
        checkWordsVC?.loader.show(customTitle: localize(string: accountType.restoreString))
        
        DataManager.shared.auth(rootKey: seedString) { [unowned self] (acc, err) in
            if self.accountType == .metamask {
                DataManager.shared.restoreMetamaskWallets(seedPhrase: seedString, completion: { [unowned self] (bool) in
                    self.toMainScreen()
                })
            } else {
                self.toMainScreen()
            }
        }
    }
    
    func toMainScreen() {
        checkWordsVC?.wordTF.resignFirstResponder()
        checkWordsVC?.navigationController?.popToRootViewController(animated: true)
        checkWordsVC?.view.isUserInteractionEnabled = true
        checkWordsVC?.loader.hide()
        
        DataManager.shared.socketManager.start()
        DataManager.shared.subscribeToFirebaseMessaging()
    }
    
//    func metaMaskSetup() {
//        segmentsCountUp = metsmaskSegmentsCountUp
//        segmentsCountDown = metamaskSegmentsCountDown
//        upperSizes = metamskUpperSizes
//        downSizes = metamaskDownSizes
//    }
//
//    func multyBricksSetup() {
//        segmentsCountUp = multySegmentsCountUp
//        segmentsCountDown = multySegmentsCountDown
//        upperSizes = multyUpperSizes
//        downSizes = multyDownSizes
//    }
}

extension LocalizeDelegate: Localizable {
    var tableName: String {
        return "Seed"
    }
}
