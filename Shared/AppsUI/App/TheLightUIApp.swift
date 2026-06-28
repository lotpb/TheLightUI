//
//  TheLightUIApp.swift
//  Shared
//
//  Created by Peter Balsamo on 6/14/21.
//

import SwiftUI
import Firebase

@available(iOS 18.0, *)
@main
struct TheLightUIApp: App {
    @State private var showLaunch = true
    private let dependencies: AppDependencies

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
                        .task {
                            try? await Task.sleep(for: .seconds(1.2))
                            guard !Task.isCancelled else { return }

                            withAnimation {
                                showLaunch = false
                            }
                        }
                }
            }
        }
    }
}
