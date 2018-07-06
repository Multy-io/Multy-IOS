//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Contacts

extension CNContact {
    func isMulty() -> Bool {
        for profile in socialProfiles {
            if profile.isMulty() {
                return true
            }
        }
        
        return false
    }
}

extension CNLabeledValue where ValueType == CNSocialProfile {
    func isMulty() -> Bool {
        return value.username == "Multy"
    }
}
