//
//  TheLightUIApp.swift
//  Shared
//
//  Created by Peter Balsamo on 6/14/21.
//

import SwiftUI
import Firebase

@available(iOS 16.0, *)
@main
struct TheLightUIApp: App {
    
//    init() {
//        FirebaseApp.configure()
//    }
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    /// This suppresses constraint warnings
                    UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
                }
        }
    }
    
    ///removes warning
    class AppDelegate:NSObject,UIApplicationDelegate{
 
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            FirebaseApp.configure()
            return true
        }
    }

}
