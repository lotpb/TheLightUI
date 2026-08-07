import SwiftUI
import Firebase

@main
struct TheLightUIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let dependencies: AppDependencies

    init() {
        // Firebase MUST be configured before `AppDependencies.live` is built:
        // `.live` eagerly constructs FirebaseSessionService, which calls
        // `Auth.auth()`, and Auth traps if the default app isn't configured yet.
        if FirebaseApp.app() == nil {
            // Load the plist whose name matches the FIREBASE_CLIENT build setting
            // (injected into Info.plist as FirebaseClientName). Fall back to the
            // default GoogleService-Info.plist if no named plist is found.
            let clientName = Bundle.main.infoDictionary?["FirebaseClientName"] as? String ?? "TheLightUI"
            if let path = Bundle.main.path(forResource: "GoogleService-Info-\(clientName)", ofType: "plist"),
               let options = FirebaseOptions(contentsOfFile: path) {
                FirebaseApp.configure(options: options)
            } else {
                FirebaseApp.configure()
            }
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

private struct AppRootView: View {
    @State private var showLaunch = true
    let dependencies: AppDependencies

    var body: some View {
        ZStack {
            ContentView(dependencies: dependencies)
                .opacity(showLaunch ? 0 : 1)
                .animation(.easeInOut(duration: 0.35), value: showLaunch)
                .task {
                    // Arm geofence monitoring for the whole session, not just
                    // while the map screen is open.
                    await GeofenceManager.shared.start()
                    // Refresh cached companyId claim for already-authenticated users.
                    await CompanySession.refresh()
                }

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
