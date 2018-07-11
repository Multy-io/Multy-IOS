//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

func isIOS9OrHigher() -> Bool {
    let versionNumber = floor(NSFoundationVersionNumber)
    return versionNumber >= NSFoundationVersionNumber_iOS_9_0
}

func isIOS10OrHigher() -> Bool {
    let versionNumber = floor(NSFoundationVersionNumber)
    return versionNumber >= NSFoundationVersionNumber10_0
}
