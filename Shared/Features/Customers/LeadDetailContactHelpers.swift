//
//  LeadDetailContactHelpers.swift
//  TheLightUI
//

import Contacts
import SwiftUI

extension LeadDetailUI {

    // MARK: - String helpers

    func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func nonEmpty(_ parts: [String], separator: String = ", ") -> String {
        parts.map { trimmed($0) }.filter { !$0.isEmpty }.joined(separator: separator)
    }

    // MARK: - Address & message body

    // Full mailing address composed from non-empty parts.
    var fullAddress: String {
        nonEmpty([detail.street, detail.city, detail.state, detail.zip])
    }

    // Default SMS body, personalized if a first name is available.
    var defaultMessageBody: String {
        let firstName = trimmed(detail.first)
        return firstName.isEmpty
            ? "Hi, following up on your inquiry."
            : "Hi \(firstName), following up on your inquiry."
    }

    // MARK: - Contact builder

    // Build a CNMutableContact from the current customer fields.
    func makeContact() -> CNMutableContact {
        let contact = CNMutableContact()
        contact.givenName = trimmed(detail.first)
        contact.familyName = trimmed(detail.lastname)

        // Phone number (if provided).
        let phone = trimmed(detail.phone)
        if !phone.isEmpty {
            contact.phoneNumbers = [CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: phone))]
        }

        // Email address (if provided).
        let email = trimmed(detail.email)
        if !email.isEmpty {
            contact.emailAddresses = [CNLabeledValue(label: CNLabelHome, value: email as NSString)]
        }

        // Postal address (if any address fields are present).
        if !fullAddress.isEmpty {
            let postalAddress = CNMutablePostalAddress()
            postalAddress.street = trimmed(detail.street)
            postalAddress.city = trimmed(detail.city)
            postalAddress.state = trimmed(detail.state)
            postalAddress.postalCode = trimmed(detail.zip)
            contact.postalAddresses = [CNLabeledValue(label: CNLabelHome, value: postalAddress)]
        }

        // Related contact: spouse (if provided).
        let spouse = trimmed(detail.spouse)
        if !spouse.isEmpty {
            contact.contactRelations = [CNLabeledValue(label: CNLabelContactRelationSpouse, value: CNContactRelation(name: spouse))]
        }

        return contact
    }

    // MARK: - Recipient parsing

    // Normalize a phone string into a single digits-only recipient array for SMS.
    func parsedRecipients(from raw: String) -> [String] {
        let digitsOnly = PhoneNumber(raw: raw).digitsOnly
        return digitsOnly.isEmpty ? [] : [digitsOnly]
    }

    // Split a raw email string on common separators and keep valid addresses.
    func parsedEmailRecipients(from raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",; ")
        return raw
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.contains("@") }
    }
}
