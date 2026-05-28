//
//  File.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 11/19/21.
//

import FirebaseFirestore

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?
    let uid, email, profileImageUrl: String
}
