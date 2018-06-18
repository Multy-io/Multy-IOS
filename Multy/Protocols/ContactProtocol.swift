//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import Contacts
import SwiftyContacts

protocol ContactsProtocol: BranchProtocol {
    func updateMyContact()
}

extension ContactsProtocol {
    func updateMyContact() {
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
                let me = "470BA82C-BD3A-49C5-BA1E-F641A9A4D73F" //"A87D45C6-C707-4387-A1A9-69A9C89BA0B6"
                
                getContactFromID(Identifires: [me], completionHandler: { (result) in
                    switch result{
                    case .Success(response: let contacts):
                        
                        print(contacts.first)
                        self.updateMyContact(contacts.first!)
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
    
    fileprivate func updateMyContact(_ contact: CNContact) {
        createDeepLink { (url) in
            guard let url = url else {
                return
            }
            
            let mContact = contact.mutableCopy() as! CNMutableContact
            
            let multyProfile = CNSocialProfile(urlString: url, username: "Multy", userIdentifier: "multy", service: "Bitcoin Address")
            let myProfile = CNLabeledValue(label: "Multy", value: multyProfile)
            
//            let multyProfile2 = CNSocialProfile(urlString: "multy://bitcoin:myUu54neP48SHXNgk5Bs3FSyMcdEcLBkz7", username: "Multy", userIdentifier: "multy", service: "myUu54neP48SHXNgk5Bs3FSyMcdEcLBkz7")
//            let myProfile2 = CNLabeledValue(label: "Multy", value: multyProfile2)
            
            mContact.socialProfiles = [myProfile]
            
            
            
            let myURL = CNLabeledValue<NSString>(label: "Bitcoin Address", value: "https://multy.app.link/d8S4NudaKN")
            mContact.urlAddresses = [myURL]
            
            updateContact(Contact: mContact) { (result) in
                switch result{
                case .Success(response: let bool):
                    if bool {
                        print("Contact Sucessfully Updated")
                    }
                    break
                case .Error(error: let error):
                    print(error.localizedDescription)
                    break
                }
            }
        }
    }
}
