//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import Contacts
import SwiftyContacts

protocol ContactsProtocol: BranchProtocol {
    
}

extension ContactsProtocol {
    func fetchPhoneContacts(completion: @escaping (_ contacts: [CNContact]?, _ error: Error?) -> ()) {
        requestAccess { (responce) in
            if responce {
                fetchContacts(completionHandler: { (result) in
                    switch result{
                    case .Success(response: let contacts):
                        // Do your thing here with [CNContacts] array
                        
                        completion(contacts, nil)
                    case .Error(error: let error):
                        print(error)
                        completion(nil, error)
                    }
                })
            } else {
                completion(nil, nil)
            }
        }
    }
    
    func updateContactInfo(_ contactID: String, with address: String?, _ currencyID: UInt32?, _ networkID: UInt32?, _ completion: @escaping(_ result: ContactsFetchResult) -> ()) {
        getContactFromID(Identifires: [contactID], completionHandler: { (result) in
            switch result {
            case .Success(response: let contacts):
                if contacts.count == 0 {
                    return
                }
                
                print(contacts.first!)
                self.updateContactInfo(contacts.first!, with: address, currencyID, networkID, completion)
                break
            case .Error(error: let error):
                print(error)
                completion(result)
                break
            }
        })
    }
    
    func updateContacts() {
        requestAccess { (responce) in
            if responce {
                fetchContacts(completionHandler: { (result) in
                    switch result{
                    case .Success(response: let contacts):
                        // Do your thing here with [CNContacts] array
                        
                        let contacts = ContactRLM.initWithArray(contacts: contacts)
                        
                        break
                    case .Error(error: let error):
                        print(error)
                        break
                    }
                })
            }
        }
    }
    
    func updateMyContact(_ completion: @escaping(_ result: ContactsFetchResult) -> ()) {
        requestAccess { (responce) in
            if responce {
                fetchContacts(completionHandler: { (result) in
                    switch result{
                    case .Success(response: let contacts):
                        // Do your thing here with [CNContacts] array
                        break
                    case .Error(error: let error):
                        print(error)
                        break
                    }
                })
                
                print("Contacts Access Granted")
                let me = /*"470BA82C-BD3A-49C5-BA1E-F641A9A4D73F"*/ "A87D45C6-C707-4387-A1A9-69A9C89BA0B6"
                
                getContactFromID(Identifires: [me], completionHandler: { (result) in
                    switch result{
                    case .Success(response: let contacts):
                        
                        print(contacts.first)
                        self.updateContactInfo(contacts.first!, with: "-------------------", 0, 0 , completion)
                        break
                    case .Error(error: let error):
                        print(error)
                        break
                    }
                })
            } else {
                print("Contacts Access Denied")
            }
        }
    }
    
    fileprivate func updateContactInfo(_ contact: CNContact, with address: String?, _ currencyID: UInt32?, _ networkID: UInt32?, _ completion: @escaping(_ result: ContactsFetchResult) -> ()) {
        createDeepLink(address) { (url) in
            guard let url = url else {
                return
            }
            
            let mContact = contact.mutableCopy() as! CNMutableContact
            
            if address == nil {
                let multyProfile = CNSocialProfile(urlString: "multy://", username: "Multy", userIdentifier: "multy", service: "Multy")
                let myProfile = CNLabeledValue(label: "Multy", value: multyProfile)
                mContact.socialProfiles = [myProfile]
            } else {
                let userID = address! + "/\(currencyID!)/\(networkID!)"
                let chainName = BlockchainType.init(blockchain: Blockchain.init(currencyID!), net_type: Int(networkID!)).fullName
                
                let multyProfile = CNSocialProfile(urlString: url, username: "Multy", userIdentifier: userID, service: chainName + " Address")
                let myProfile = CNLabeledValue(label: "Multy", value: multyProfile)
                mContact.socialProfiles = [myProfile]
            }
            
            updateContact(Contact: mContact) { (result) in
                switch result {
                case .Success(response: let bool):
                    if bool {
                        print("Contact Sucessfully Updated")
                        completion(ContactsFetchResult.Success(response: []))
                    } else {
                        completion(ContactsFetchResult.Success(response: []))
                    }
                case .Error(error: let error):
                    print(error.localizedDescription)
                    completion(ContactsFetchResult.Error(error: error))
                    break
                }
            }
        }
    }
}
