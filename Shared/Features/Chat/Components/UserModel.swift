//
//  UserModel.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 11/19/21.
//

import FirebaseFirestore

// `@unchecked Sendable`: a value type whose only non-Sendable member is
// Firebase's `@DocumentID` wrapper around an optional String, which is safe
// to share given the struct's value semantics.
struct UserModel: Codable, Identifiable, @unchecked Sendable {
    @DocumentID var id: String?
    let uid, email, profileImageUrl: String
    let firstName: String?
    let lastName: String?

    init(id: String? = nil, uid: String, email: String, profileImageUrl: String, firstName: String? = nil, lastName: String? = nil) {
        self.id = id
        self.uid = uid
        self.email = email
        self.profileImageUrl = profileImageUrl
        self.firstName = firstName
        self.lastName = lastName
    }

    var username: String {
        email.components(separatedBy: "@").first ?? email
    }

    var displayName: String {
        let parts = [firstName, lastName].compactMap { s -> String? in
            guard let s, !s.isEmpty else { return nil }
            return s
        }
        return parts.isEmpty ? username : parts.joined(separator: " ")
    }
}
