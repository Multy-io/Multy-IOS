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
    
    func isThereUserID(_ userID: String) -> Bool {
        for socialProfile in socialProfiles {
            if socialProfile.value.userIdentifier == userID {
                return true
            }
        }
        
        return false
    }
    
    func isThereMultyUserID() -> Bool {
        return isThereUserID("Multy")
    }
}

extension CNLabeledValue where ValueType == CNSocialProfile {
    func isMulty() -> Bool {
        return value.username == "Multy"
    }
    
    func isThereAddress() -> Bool {
        return value.service != "Multy"
    }
}
