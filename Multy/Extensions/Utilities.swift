//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import UIKit

func isIOS9OrHigher() -> Bool {
    let versionNumber = floor(NSFoundationVersionNumber)
    return versionNumber >= NSFoundationVersionNumber_iOS_9_0
}

func isIOS10OrHigher() -> Bool {
    let versionNumber = floor(NSFoundationVersionNumber)
    return versionNumber >= NSFoundationVersionNumber10_0
}

func viewControllerFrom(_ storyboardName: String, _ vcIdentifier: String) -> UIViewController {
    let stroryboard = UIStoryboard(name: storyboardName, bundle: nil)
    let vc = stroryboard.instantiateViewController(withIdentifier: vcIdentifier)
    
    return vc
}

func saveAddressesToUD(_ addresses: [String: String]) {
    UserDefaults.standard.set(addresses, forKey: "savedAddresses")
}

func fetchAddressesFromUD() -> [String: String] {
    let addresses = UserDefaults.standard.dictionary(forKey: "savedAddresses") as? [String: String]
    
    return addresses == nil ? [String: String]() : addresses!
}
