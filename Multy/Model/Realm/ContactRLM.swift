//Copyright 2018 Idealnaya rabota LLC
//Licensed under Multy.io license.
//See LICENSE for details

import Foundation
import RealmSwift
import Contacts

class ContactRLM: Object {
    @objc dynamic var id = String()
    @objc dynamic var avatarURL = String()
    var addresses = List<AddressRLM>()
    
    public class func initWithArray(contacts: [CNContact]) -> List<ContactRLM> {
        let contactsRLM = List<ContactRLM>()
        
        for contact in contacts {
            //FIXME: add logic for Multy-Contact
            let contactRLM = ContactRLM.initWithInfo(contact)
            contactsRLM.append(contactRLM)
        }
        
        return contactsRLM
    }
    
    public class func initWithInfo(_ contactInfo: CNContact) -> ContactRLM {
        let contact = ContactRLM()
        
        return contact
    }
}
