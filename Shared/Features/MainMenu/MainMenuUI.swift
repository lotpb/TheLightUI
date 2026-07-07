//
//  MainMenuUI.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/10/21.
//

import SwiftUI

// MARK: - Main Menu
@MainActor
struct MainMenuUI: View {
    @AppStorage("color") private var color: Int?
    @Environment(\.tabBarOverlap) private var tabBarOverlap
    let onSignOut: () -> Void
    private let makeCustomerService: () -> CustomerServicing
    private let makeCustomerFormService: () -> CustomerFormServicing
    private let makeWeatherManager: () -> WeatherManaging
    private let makeWeatherLocationProvider: () -> WeatherLocationProviding
    private let appBadgeManager: AppBadgeManaging
    @State private var showingLogOut = false
    @State private var activeSheet: MainMenuSheet?
    @State private var activeRoute: MainMenuFullscreenRoute?
    @State private var path: [MainMenuDataRoute] = []

    init(
        onSignOut: @escaping () -> Void,
        makeCustomerService: @escaping () -> CustomerServicing = { FirebaseCustomerService() },
        makeCustomerFormService: @escaping () -> CustomerFormServicing = { FirebaseCustomerFormService() },
        makeWeatherManager: @escaping () -> WeatherManaging = { WeatherManager() },
        makeWeatherLocationProvider: @escaping () -> WeatherLocationProviding = { LocationWeatherManager() },
        appBadgeManager: AppBadgeManaging = LiveAppBadgeManager()
    ) {
        self.onSignOut = onSignOut
        self.makeCustomerService = makeCustomerService
        self.makeCustomerFormService = makeCustomerFormService
        self.makeWeatherManager = makeWeatherManager
        self.makeWeatherLocationProvider = makeWeatherLocationProvider
        self.appBadgeManager = appBadgeManager
    }

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    private var coordinator: MainMenuCoordinator {
        MainMenuCoordinator(
            makeCustomerService: makeCustomerService,
            makeCustomerFormService: makeCustomerFormService,
            makeWeatherManager: makeWeatherManager,
            makeWeatherLocationProvider: makeWeatherLocationProvider,
            appBadgeManager: appBadgeManager,
            dismissSheet: { activeSheet = nil }
        )
    }

    var body: some View {
        navigationContainer
            .tint(themeColor)
    }

    private var navigationContainer: some View {
        NavigationStack(path: $path) {
            mainContent
        }
    }

    private var mainContent: some View {
        VStack {
            MainTopView(
                makeWeatherManager: makeWeatherManager,
                makeWeatherLocationProvider: makeWeatherLocationProvider
            )
            .padding(.top, 25)

            menuList
        }
        .navigationTitle("Main Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        // Confirmation dialogs get an automatic Cancel button; the title asks
        // the question directly per the HIG pattern for destructive actions.
        .confirmationDialog("Are you sure you want to sign out?", isPresented: $showingLogOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { handleSignOut() }
        }
        .sheet(item: $activeSheet) { sheet in
            coordinator.sheetContent(sheet)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                showingLogOut.toggle()
            } label: {
                Label("Sign Out", systemImage: "gearshape")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                actionDialogButtons
            } label: {
                Label("More", systemImage: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private var actionDialogButtons: some View {
        #if DEBUG
        Button { showModal(.about) } label: {
            Label("About", systemImage: "info.circle")
        }
        #endif
        Button { activeSheet = .email } label: {
            Label("Email Support", systemImage: "envelope")
        }
        Button { showModal(.settings) } label: {
            Label("Settings", systemImage: "gearshape")
        }
        Button { showModal(.directions) } label: {
            Label("Directions", systemImage: "map")
        }
        Button { showModal(.users) } label: {
            Label("Users", systemImage: "person.2")
        }
        Button { showModal(.membership) } label: {
            Label("Membership Card", systemImage: "creditcard")
        }
    }

    private var menuList: some View {
        List {
            #if DEBUG
            IncomingSection(themeColor: themeColor)
            #endif
            DataSection(themeColor: themeColor) { route in
                path.append(route)
            }
            OutgoingSection(
                themeColor: themeColor,
                onSelectRoute: showRoute
            )
        }
        .listStyle(.insetGrouped)
        // The custom tab bar's safe-area inset is applied outside this
        // screen's NavigationStack, which doesn't forward it to the List's
        // scroll insets — re-apply it so the last row rests above the bar.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: tabBarOverlap)
                .allowsHitTesting(false)
        }
        .fullScreenCover(item: $activeRoute) { route in
            coordinator.fullscreenDestination(route)
        }
        .navigationDestination(for: MainMenuDataRoute.self) { route in
            coordinator.dataDestination(route)
        }
    }

    private func showModal(_ modal: MainMenuModal) {
        activeSheet = .modal(modal)
    }

    private func showRoute(_ route: MainMenuFullscreenRoute) {
        activeRoute = route
    }

    private func handleSignOut() {
        onSignOut()
        HapticManager.notification(type: .success)
    }
}

// MARK: - Preview
#Preview {
    MainMenuUI(
        onSignOut: { },
        makeCustomerService: { PreviewCustomerService() },
        makeCustomerFormService: { PreviewCustomerFormService() },
        makeWeatherManager: { PreviewWeatherManager() },
        makeWeatherLocationProvider: { PreviewWeatherLocationProvider() },
        appBadgeManager: PreviewAppBadgeManager()
    )
    .preferredColorScheme(.dark)
}
