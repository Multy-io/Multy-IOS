//
//  Utilities.swift
//  Multy
//
//  Created by Artyom Alekseev on 04.06.2018.
//  Copyright © 2018 Idealnaya rabota. All rights reserved.
//

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
