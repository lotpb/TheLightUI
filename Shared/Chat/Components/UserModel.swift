//
//  File.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 11/19/21.
//

import FirebaseFirestoreSwift

struct UserModel: Codable, Identifiable {
    @DocumentID var id: String?
    let uid, email, profileImageUrl: String
}
