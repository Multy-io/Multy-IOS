//
//  EPContact.swift
//  EPContacts
//
//  Created by Prabaharan Elangovan on 13/10/15.
//  Copyright © 2015 Prabaharan Elangovan. All rights reserved.
//

import UIKit
import Contacts

open class EPContact {
    open var firstName: String
    open var lastName: String
    open var company: String
    open var thumbnailProfileImage: UIImage?
    open var profileImage: UIImage?
    open var birthday: Date?
    open var birthdayString: String?
    open var contactId: String?
    open var phoneNumbers = [(phoneNumber: String, phoneLabel: String)]()
    open var emails = [(email: String, emailLabel: String )]()
    var addresses = [AddressRLM]()
	
    public init (contact: CNContact) {
        firstName = contact.givenName
        lastName = contact.familyName
        company = contact.organizationName
        contactId = contact.identifier
        
        if let thumbnailImageData = contact.thumbnailImageData {
            thumbnailProfileImage = UIImage(data:thumbnailImageData)
        }
        
        if let imageData = contact.imageData {
            profileImage = UIImage(data:imageData)
        }
        
        if let birthdayDate = contact.birthday {
            birthday = Calendar(identifier: Calendar.Identifier.gregorian).date(from: birthdayDate)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = EPGlobalConstants.Strings.birthdayDateFormat
            //Example Date Formats:  Oct 4, Sep 18, Mar 9
            birthdayString = dateFormatter.string(from: birthday!)
        }
        
		for phoneNumber in contact.phoneNumbers {
            		var phoneLabel = "phone"
            		if let label = phoneNumber.label {
            		    phoneLabel = label
            		}
			let phone = phoneNumber.value.stringValue
			phoneNumbers.append((phone,phoneLabel))
		}
		
		for emailAddress in contact.emailAddresses {
			guard let emailLabel = emailAddress.label else { continue }
			let email = emailAddress.value as String
			emails.append((email,emailLabel))
		}
        
        if contact.isMulty() {
            addresses.removeAll()

            for socialProfile in contact.socialProfiles {
                if socialProfile.isMulty() && socialProfile.isThereAddress() {
                    let addressRLM = convertProfileToAddress(socialProfile)
                    addresses.append(addressRLM)
                }
            }
        }
    }
    
    class func initFromArray(_ contacts: [CNContact]) -> [EPContact] {
        var parsedContacts = [EPContact]()
        
        for contact in contacts {
            parsedContacts.append(EPContact(contact: contact))
        }
        
        return parsedContacts
    }
    
    func convertProfileToAddress(_ profile: CNLabeledValue<CNSocialProfile>) -> AddressRLM {
        let address = AddressRLM()
        
        let addressInfo = profile.value.userIdentifier.components(separatedBy: "/")
        
        if addressInfo.count != 3 {
            return address
        }
        
        address.address = addressInfo[0]
        address.currencyID = NSNumber(value: UInt32(addressInfo[1])!)
        address.networkID = NSNumber(value: UInt32(addressInfo[2])!)
        
        return address
    }
	
    open func displayName() -> String {
        if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return firstName + " " + lastName
        }
    }
    
    open func contactInitials() -> String {
        var initials = String()
		
		if let firstNameFirstChar = firstName.characters.first {
			initials.append(firstNameFirstChar)
		}
		
		if let lastNameFirstChar = lastName.characters.first {
			initials.append(lastNameFirstChar)
		}
		
        return initials
    }
    
}
