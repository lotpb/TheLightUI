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
    private let dependencies: AppDependencies

    init() {
        // Firebase MUST be configured before `AppDependencies.live` is built:
        // `.live` eagerly constructs FirebaseSessionService, which calls
        // `Auth.auth()`, and Auth traps if the default app isn't configured yet.
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        dependencies = .live
    }

    var body: some Scene {
        WindowGroup {
            // Keep this closure free of @State captures: SwiftUI's async render
            // thread can re-evaluate the root content closure, and a MainActor
            // isolation assert then crashes the app (see device crash logs from
            // 2026-07-03). Launch-overlay state lives in AppRootView instead.
            AppRootView(dependencies: dependencies)
        }
    }
}

@available(iOS 18.0, *)
private struct AppRootView: View {
    @State private var showLaunch = true
    let dependencies: AppDependencies

    var body: some View {
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
