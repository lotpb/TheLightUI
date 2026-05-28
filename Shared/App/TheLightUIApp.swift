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
    
    @State private var showLaunch = true
    private let dependencies: AppDependencies
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        dependencies = .live
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(dependencies: dependencies)
                    .opacity(showLaunch ? 0 : 1)
                    .animation(.easeInOut(duration: 0.35), value: showLaunch)

                if showLaunch {
                    LaunchScreenView()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.35), value: showLaunch)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation {
                                    showLaunch = false
                                }
                            }
                        }
                }
            }
            .onAppear {
                /// This suppresses constraint warnings
                UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
            }
        }
    }
    
    ///removes warning
    class AppDelegate:NSObject,UIApplicationDelegate{
 
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
            if FirebaseApp.app() == nil {
                FirebaseApp.configure()
            }
            return true
        }
    }

}
