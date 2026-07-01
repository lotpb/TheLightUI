//
//  File.swift
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
}
