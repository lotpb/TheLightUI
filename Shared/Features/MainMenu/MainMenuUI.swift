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
    let onSignOut: () -> Void
    private let makeCustomerService: () -> CustomerServicing
    private let makeCustomerFormService: () -> CustomerFormServicing
    private let makeWeatherManager: () -> WeatherManaging
    private let makeWeatherLocationProvider: () -> WeatherLocationProviding
    private let appBadgeManager: AppBadgeManaging
    @State private var showingLogOut = false
    @State private var isShowingActionDialog = false
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
            .accentColor(themeColor)
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
        .confirmationDialog("Settings", isPresented: $showingLogOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) { handleSignOut() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("What do you want to do?")
        }
        .confirmationDialog("Pick a menu item", isPresented: $isShowingActionDialog, titleVisibility: .visible) {
            actionDialogButtons
        }
        .sheet(item: $activeSheet) { sheet in
            coordinator.sheetContent(sheet)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingLogOut.toggle()
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .font(.footnote)
            .fontWeight(.bold)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                isShowingActionDialog.toggle()
            } label: {
                Label("Action", systemImage: "square.and.arrow.up")
            }
        }
    }

    @ViewBuilder
    private var actionDialogButtons: some View {
        #if DEBUG
        Button("About") { showModal(.about) }
        #endif
        Button("Email Support") { activeSheet = .email }
        Button("Settings") { showModal(.settings) }
        Button("Directions") { showModal(.directions) }
        Button("Users") { showModal(.users) }
        Button("Membership Card") { showModal(.membership) }
        Button("Cancel", role: .cancel) { }
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
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 72)
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
@available(iOS 18.0, *)
struct MainMenuUI_Previews: PreviewProvider {
    static var previews: some View {
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
}
