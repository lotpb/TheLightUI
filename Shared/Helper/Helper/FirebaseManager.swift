//
//  FirebaseManager.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/17/21.
//

import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

/// Shared Firebase services for chat, login, and storage flows.
final class FirebaseManager: NSObject {
    static let shared = FirebaseManager()
    
    let auth: Auth
    let storage: Storage
    let firestore: Firestore
    
    var currentUser: UserModel?
    
    private override init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        auth = Auth.auth()
        storage = Storage.storage()
        firestore = Firestore.firestore()
        
        super.init()
    }
}
