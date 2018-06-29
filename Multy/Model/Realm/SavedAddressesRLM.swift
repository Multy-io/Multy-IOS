//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift

class SavedAddressesRLM: Object {
    @objc dynamic var addressesData: Data?
    var addresses: [String: String] {
        get {
            guard let data = addressesData else {
                return [String: String]()
            }

            do {
                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
                
                return dict!
            } catch {
                return [String: String]()
            }
        }
        
        set {
            do {
                let data = try JSONSerialization.data(withJSONObject: newValue, options: [])
                addressesData = data
                
                DataManager.shared.updateSavedAddresses(self) { _ in }
            } catch {
                addressesData = nil
            }
        }
    }
    
    func mapAddressesAndSave(_ contacts: [EPContact]) {
        var localAddresses = Dictionary<String, String>()
        
        for contact in contacts {
            for addressRLM in contact.addresses {
                //check if exist address for another user
                if localAddresses[addressRLM.address] == nil {
                    localAddresses[addressRLM.address] = contact.displayName()
                }
            }
        }
        
        addresses = localAddresses
    }
    
    override static func ignoredProperties() -> [String] {
        return ["addresses"]
    }
}
