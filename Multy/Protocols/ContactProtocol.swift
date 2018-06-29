//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import Contacts
import SwiftyContacts

protocol ContactsProtocol: BranchProtocol {
    
}

extension ContactsProtocol {
    func addAddress(_ address: String, to contact: String) {
        
    }
    
    func fetchPhoneContact(_ contactID: String, completion: @escaping (_ contacts: CNContact?, _ error: Error?) -> ()) {
        getContactFromID(Identifires: [contactID], completionHandler: { (result) in
            switch result {
            case .Success(response: let contacts):
                if contacts.count == 0 {
                    completion(nil, nil)
                    return
                }
                
                completion(contacts.first, nil)
                break
            case .Error(error: let error):
                print(error)
                completion(nil, error)
                break
            }
        })
    }
    
    func fetchPhoneContacts(completion: @escaping (_ contacts: [CNContact]?, _ error: Error?) -> ()) {
        requestAccess { (responce) in
            if responce {
                fetchContacts(completionHandler: { (result) in
                    switch result{
                    case .Success(response: let contacts):
                        
                        self.updateAddressMapping(contacts) // update mapping addresses for UI
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
    
    func deleteContact(_ contactID: String, _ completion: @escaping(_ result: ContactOperationResult) -> ()) {
        getContactFromID(Identifires: [contactID], completionHandler: { (result) in
            switch result {
            case .Success(response: let contacts):
                if contacts.count == 0 {
                    return
                }
                
                self.deleteAddressesFromContact(contacts.first!, { (result) in
                    completion(result)
                })
                break
            case .Error(error: let error):
                print(error)
                completion(ContactOperationResult.Error(error: error))
                break
            }
        })
    }
    
    fileprivate func deleteAddressesFromContact(_ contact: CNContact, _ completion: @escaping(_ result: ContactOperationResult) -> ()) {
        let mContact = contact.mutableCopy() as! CNMutableContact
        var newSocialProfiles = [CNLabeledValue<CNSocialProfile>]()
        
        for socialProfile in contact.socialProfiles {
            if socialProfile.isMulty() == false {
                newSocialProfiles.append(socialProfile)
            }
        }
        
        mContact.socialProfiles = newSocialProfiles
        
        customUpdateContact(mContact) { (result) in
            completion(result)
        }
    }
    
    func updateContactInfo(_ contactID: String, withAddress address: String?, _ currencyID: UInt32?, _ networkID: UInt32?, _ completion: @escaping(_ result: ContactsFetchResult) -> ()) {
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
    
    func deleteAddress(_ address: String, from contactID: String, _ completion: @escaping(_ result: ContactOperationResult) -> ()) {
        getContactFromID(Identifires: [contactID], completionHandler: { (result) in
            switch result {
            case .Success(response: let contacts):
                if contacts.count == 0 {
                    return
                }
                
                print(contacts.first!)
                self.deleteAddress(address, from: contacts.first!, { (result) in
                    completion(result)
                })
                break
            case .Error(error: let error):
                print(error)
                completion(ContactOperationResult.Error(error: error))
                break
            }
        })
    }
    
    fileprivate func updateContactInfo(_ contact: CNContact, with address: String?, _ currencyID: UInt32?, _ networkID: UInt32?, _ completion: @escaping(_ result: ContactsFetchResult) -> ()) {
        createDeepLink(address) { (url) in
            guard let url = url else {
                return
            }
            
            let mContact = contact.mutableCopy() as! CNMutableContact
            
            //added Multy User ID// to enter in Multy App
            if address == nil {
                let multyProfile = CNSocialProfile(urlString: "multy://", username: "Multy", userIdentifier: "multy", service: "Multy")
                let myProfile = CNLabeledValue(label: "Multy", value: multyProfile)
                
                if contact.isThereMultyUserID() == false {
                    mContact.socialProfiles.append(myProfile)
                }
            } else { //added User ID// to enter in Multy App with address
                let userID = address! + "/\(currencyID!)/\(networkID!)"
                let chainName = BlockchainType.init(blockchain: Blockchain.init(currencyID!), net_type: Int(networkID!)).fullName
                
                let multyProfile = CNSocialProfile(urlString: url, username: "Multy", userIdentifier: userID, service: chainName + " Address")
                let myProfile = CNLabeledValue(label: "Multy", value: multyProfile)
                
                if contact.isThereUserID(userID) == false {
                    mContact.socialProfiles.append(myProfile)
                }
            }
            
            updateContact(Contact: mContact) { (result) in
                switch result {
                case .Success(response: let bool):
                    // to update mapping
                    self.fetchPhoneContacts(completion: { _,_  in
                        if bool {
                            print("Contact Sucessfully Updated")
                            completion(ContactsFetchResult.Success(response: []))
                        } else {
                            completion(ContactsFetchResult.Success(response: []))
                        }
                    })
                case .Error(error: let error):
                    print(error.localizedDescription)
                    completion(ContactsFetchResult.Error(error: error))
                    break
                }
            }
        }
    }
    
    fileprivate func deleteAddress(_ address: String, from contact: CNContact, _ completion: @escaping(_ result: ContactOperationResult) -> ()) {
        let mContact = contact.mutableCopy() as! CNMutableContact
        
        var newSocialProfiles = [CNLabeledValue<CNSocialProfile>]()
        
        for socialProfile in contact.socialProfiles {
            if socialProfile.value.userIdentifier.hasPrefix(address) == false {
                newSocialProfiles.append(socialProfile)
            }
        }
    
        mContact.socialProfiles = newSocialProfiles
        
        customUpdateContact(mContact) { (result) in
            completion(result)
        }
    }
    
    fileprivate func customUpdateContact(_ contact: CNMutableContact, _ completion: @escaping(_ result: ContactOperationResult) -> ()) {
        updateContact(Contact: contact) { (result) in
            switch result {
            case .Success(response: let bool):
                
                DispatchQueue.main.async {
                    self.fetchPhoneContacts(completion: { _,_  in }) // to update mapping
                }
                
                if bool {
                    print("Contact Sucessfully Updated")
                    completion(result)
                } else {
                    completion(result)
                }
            case .Error(error: let error):
                print(error.localizedDescription)
                completion(ContactOperationResult.Error(error: error))
                break
            }
        }
    }
    
    fileprivate func updateAddressMapping(_ contacts: [CNContact]) {
        let multyContacts = contacts.filter { contact in contact.isMulty() }
        
        DispatchQueue.main.async {
            let contacts = EPContact.initFromArray(multyContacts)
            SavedAddressesRLM().mapAddressesAndSave(contacts)
        }
    }
}
