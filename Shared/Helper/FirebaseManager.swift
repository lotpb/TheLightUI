//
//  FirebaseManager.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/17/21.
//

import Foundation
import Firebase
import FirebaseStorage

///Chat LoginView
class FirebaseManager: NSObject {

    let auth: Auth
    let storage: Storage
    let firestore: Firestore

    var currentUser: UserModel?

    static let shared = FirebaseManager()

    override init() {
        //FirebaseApp.configure()

        self.auth = Auth.auth()
        self.storage = Storage.storage()
        self.firestore = Firestore.firestore()

        super.init()
    }
}
