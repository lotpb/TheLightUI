//
//  MainMenuUI.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/10/21.
//

import SwiftUI

// MARK: - Main Menu
@available(iOS 16.0, *)
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
        NavigationStack(path: $path) {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingLogOut.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .font(.footnote).fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingActionDialog.toggle()
                    } label: {
                        Label("Action", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .confirmationDialog("Settings", isPresented: $showingLogOut, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { handleSignOut() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("What do you want to do?")
            }
            .confirmationDialog("Pick a menu item", isPresented: $isShowingActionDialog, titleVisibility: .visible) {
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
            .sheet(item: $activeSheet) { sheet in
                coordinator.sheetContent(sheet)
            }
        }
        .accentColor(themeColor)
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

private struct IncomingSection: View {
    let themeColor: Color
    private let menuItems = ["Snapshot", "Statistics"]

    var body: some View {
        Section(header: Text("Incoming").foregroundColor(themeColor)) {
            ForEach(menuItems, id: \.self) { message in
                NavigationLink {
                    incomingDestination(for: message)
                } label: {
                    incomingLabel(message)
                }
            }
        }
    }

    @ViewBuilder
    private func incomingDestination(for message: String) -> some View {
        switch message {
        case "Statistics":
            SpotifyUI()
        default:
            GlassMorphism()
        }
    }

    private func incomingLabel(_ message: String) -> some View {
        Label(message, systemImage: "message")
            .badge("NEW ITEMS!")
            .listItemTint(themeColor)
    }
}

private struct DataSection: View {
    let themeColor: Color
    let onSelect: (MainMenuDataRoute) -> Void

    var body: some View {
        Section(header: Text("Data").foregroundColor(themeColor)) {
            MenuRouteButton(
                title: "Leads",
                subtitle: "Potential customers",
                systemImage: "person.crop.circle.badge.plus",
                tint: themeColor,
                isCompact: true
            ) { onSelect(.leads) }

            MenuRouteButton(
                title: "Customers",
                subtitle: "Active accounts",
                systemImage: "person.2.fill",
                tint: themeColor,
                isCompact: true
            ) { onSelect(.customers) }

            #if DEBUG
            MenuRouteButton(
                title: "Vendors",
                subtitle: "Suppliers",
                systemImage: "shippingbox.fill",
                tint: themeColor,
                isCompact: true
            ) { onSelect(.vendors) }

            MenuRouteButton(
                title: "Employee",
                subtitle: "Team directory",
                systemImage: "person.text.rectangle",
                tint: themeColor,
                isCompact: true
            ) { onSelect(.employee) }
            #endif

            if #available(iOS 17.0, *) {
                MenuRouteButton(
                    title: "Expenses",
                    subtitle: "Track spending",
                    systemImage: "creditcard.fill",
                    tint: themeColor,
                    isCompact: true
                ) { onSelect(.expenses) }
            }
        }
    }
}

private struct OutgoingSection: View {
    let themeColor: Color
    let onSelectRoute: (MainMenuFullscreenRoute) -> Void

    var body: some View {
        Section(header: Text("Outgoing").foregroundColor(themeColor)) {
            #if DEBUG
            MenuRouteButton(
                title: "Chart",
                subtitle: "Analytics",
                systemImage: "chart.bar.fill",
                tint: themeColor,
                isCompact: true
            ) { onSelectRoute(.chart) }
            #endif
            
            MenuRouteButton(
                title: "Geotify",
                subtitle: "Region monitoring",
                tint: themeColor,
                isCompact: true
            ) { onSelectRoute(.geotify) }

            MenuRouteButton(
                title: "Search Places",
                subtitle: "Find a place nearby",
                systemImage: "magnifyingglass.circle.fill",
                tint: themeColor,
                isCompact: true
            ) { onSelectRoute(.places) }

            MenuRouteButton(
                title: "Weather",
                subtitle: "Forecast and conditions",
                systemImage: "cloud.sun.fill",
                tint: themeColor,
                isCompact: true
            ) { onSelectRoute(.weather) }

            #if DEBUG
            MenuRouteButton(
                title: "Stacks",
                subtitle: "Layout demos",
                systemImage: "square.stack.3d.up.fill",
                tint: themeColor,
                isCompact: true
            ) { onSelectRoute(.stacks) }

            MenuRouteButton(
                title: "Instagram",
                subtitle: "Social feed",
                systemImage: "camera.circle.fill",
                tint: themeColor,
                isCompact: true
            ) { onSelectRoute(.instagram) }
            #endif
        }
        .foregroundColor(.primary)
    }
}

private struct MenuRouteButton: View {
    var title: String
    var subtitle: String? = nil
    var systemImage: String = "mappin.and.ellipse"
    var tint: Color = .accentColor
    var isCompact = false
    var action: () -> Void

    private var iconSize: CGFloat {
        isCompact ? 32 : 40
    }

    private var verticalPadding: CGFloat {
        isCompact ? 4 : 8
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: isCompact ? 10 : 12) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: iconSize, height: iconSize)
                    Image(systemName: systemImage)
                        .foregroundStyle(tint)
                        .imageScale(isCompact ? .medium : .large)
                }

                VStack(alignment: .leading, spacing: isCompact ? 1 : 2) {
                    Text(title)
                        .font(isCompact ? .subheadline.weight(.semibold) : .headline)
                    if let subtitle {
                        Text(subtitle)
                            .font(isCompact ? .caption : .subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(isCompact ? .caption : .body)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, verticalPadding)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(subtitle != nil ? "\(title), \(subtitle!)" : title))
    }
}

// MARK: - Preview
@available(iOS 16.0, *)
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

// MARK: - Header
struct MainTopView: View {
    private enum Layout {
        static let height: CGFloat = 115
        static let cornerRadius: CGFloat = 20
        static let titleSize: CGFloat = 32
    }

    @AppStorage("color") private var color: Int?
    @AppStorage(SettingsUI.isCompanyNameKey) private var companyName: String = "Main Menu"
    @AppStorage(SettingsUI.backend) private var backEnd: String = "None"
    @State private var currentTemperatureText = "--°F"

    private let makeWeatherManager: () -> WeatherManaging
    private let makeWeatherLocationProvider: () -> WeatherLocationProviding

    init(
        makeWeatherManager: @escaping () -> WeatherManaging = { WeatherManager() },
        makeWeatherLocationProvider: @escaping () -> WeatherLocationProviding = { LocationWeatherManager() }
    ) {
        self.makeWeatherManager = makeWeatherManager
        self.makeWeatherLocationProvider = makeWeatherLocationProvider
    }

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    var body: some View {
        VStack(alignment: .leading) {
            titleRow
            Divider()
            backendRow
            Spacer()
            weatherRow
        }
        .symbolRenderingMode(.multicolor)
        .foregroundColor(.white)
        .background(themeColor)
        .cornerRadius(Layout.cornerRadius)
        .frame(height: Layout.height, alignment: .leading)
        .padding()
        .task {
            await loadCurrentTemperature()
        }
    }

    private var titleRow: some View {
        HStack {
            Text(companyName)
                .font(.system(size: Layout.titleSize, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.9)
                .padding(.top, 15)
                .padding(.leading, 15)
        }
    }

    private var backendRow: some View {
        statusRow(title: "Backend:", value: backEnd, systemImage: "circle.hexagongrid.fill")
    }

    private var weatherRow: some View {
        statusRow(title: "Temp:", value: currentTemperatureText, systemImage: "thermometer.sun.fill")
            .padding(.bottom, 15)
    }

    @MainActor
    private func loadCurrentTemperature() async {
        do {
            let coordinates = try await makeWeatherLocationProvider().requestLocation()
            let weather = try await makeWeatherManager().getCurrentWeather(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            currentTemperatureText = "\(Int(weather.main.temp.rounded()))°F"
        } catch {
            currentTemperatureText = "Unavailable"
        }
    }

    private func statusRow(title: String, value: String, systemImage: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
            Image(systemName: systemImage)
                .font(.callout)
                .imageScale(.large)
        }
        .font(.callout.bold())
        .padding(.horizontal)
    }
}

