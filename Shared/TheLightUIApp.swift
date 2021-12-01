//
//  TheLightUIApp.swift
//  Shared
//
//  Created by Peter Balsamo on 6/14/21.
//

import SwiftUI
import Firebase

@available(iOS 15.0, *)
@main
struct TheLightUIApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            //HalfSheet()
            MainMessagesView()
        }
    }
}
