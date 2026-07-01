//
//  FirebaseManager.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 11/17/21.
//

import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import os

/// Shared Firebase services for chat, login, and storage flows.
///
/// Marked `@unchecked Sendable` because the Firebase service objects are
/// immutable references shared safely across threads, and the only mutable
/// state (`currentUser`) is guarded by a lock.
final class FirebaseManager: NSObject, @unchecked Sendable {
    static let shared = FirebaseManager()

    let auth: Auth
    let storage: Storage
    let firestore: Firestore

    private let currentUserLock = OSAllocatedUnfairLock<UserModel?>(initialState: nil)

    /// The signed-in chat user, accessed safely from any thread.
    var currentUser: UserModel? {
        get { currentUserLock.withLock { $0 } }
        set { currentUserLock.withLock { $0 = newValue } }
    }

    private override init() {
        auth = Auth.auth()
        storage = Storage.storage()
        firestore = Firestore.firestore()
        
        super.init()
    }
}
