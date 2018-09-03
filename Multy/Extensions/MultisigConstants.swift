//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation

enum ConfirmationStatus : Int {
    case
    waiting = 1,
    viewed = 2,
    confirmed = 3,
    declined = 4
}

enum DeployStatus : Int {
    case
    created =     1,
    ready =       2,
    pending =     3,
    rejected =    4,
    deployed =    5
}
