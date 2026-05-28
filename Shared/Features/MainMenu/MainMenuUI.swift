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
    private enum ModalContent {
        case settings
        case directions
        case users
        case membership
    }

    @AppStorage("color") private var color: Int?
    let onSignOut: () -> Void
    private let customerService: CustomerServicing
    private let customerFormService: CustomerFormServicing
    @State private var showingLogOut = false
    @State private var isShowingActionDialog = false
    @State private var selectedModal: ModalContent = .settings

    @State private var activeSheet: ActiveSheet?
    @State private var activeRoute: ActiveRoute?

    private enum ActiveSheet: Identifiable {
        case modal(ModalContent)
        case email

        var id: String {
            switch self {
            case .modal(let modal):
                return "modal_\(modal)"
            case .email:
                return "email"
            }
        }
    }

    fileprivate enum ActiveRoute: Identifiable {
        case geotify
        case places
        case weather
        case stacks
        case contacts

        var id: Self { self }
    }

    init(
        onSignOut: @escaping () -> Void,
        customerService: CustomerServicing = FirebaseCustomerService(),
        customerFormService: CustomerFormServicing = FirebaseCustomerFormService()
    ) {
        self.onSignOut = onSignOut
        self.customerService = customerService
        self.customerFormService = customerFormService
    }

    private var themeColor: Color {
        color == 0 ? .purple : .orange
    }

    var body: some View {
        NavigationStack {
            VStack {
                MainTopView().padding(.top, 25)
                menuList
            }
            .navigationTitle("Main Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") { showingLogOut.toggle() }
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
                Button("Email Support") { activeSheet = .email }
                Button("Settings") { showModal(.settings) }
                Button("Directions") { showModal(.directions) }
                Button("Users") { showModal(.users) }
                Button("Membership Card") { showModal(.membership) }
                Button("Cancel", role: .cancel) { }
            }
            .sheet(item: $activeSheet, content: sheetContent)
        }
        .accentColor(themeColor)
    }

    private var menuList: some View {
        List {
            IncomingSection(themeColor: themeColor)
            DataSection(
                themeColor: themeColor,
                customerService: customerService,
                customerFormService: customerFormService
            )
            OutgoingSection(
                themeColor: themeColor,
                onSelectRoute: showRoute
            )
        }
        .listStyle(.insetGrouped)
        .fullScreenCover(item: $activeRoute, content: routeContent)
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ActiveSheet) -> some View {
        switch sheet {
        case .modal:
            modalContent
        case .email:
            MailView(
                subject: "Email support",
                message: "Message",
                attachment: nil,
                onResult: { _ in activeSheet = nil }
            )
        }
    }

    @ViewBuilder
    private var modalContent: some View {
        switch selectedModal {
        case .settings:
            SettingView()
        case .directions:
            DirectionsUI()
        case .users:
            UserFormUI()
        case .membership:
            MembershipUI()
        }
    }

    private func showModal(_ modal: ModalContent) {
        selectedModal = modal
        activeSheet = .modal(modal)
    }

    private func showRoute(_ route: ActiveRoute) {
        activeRoute = route
    }

    @ViewBuilder
    private func routeContent(_ route: ActiveRoute) -> some View {
        switch route {
        case .geotify:
            MapUI(travelTime: 0.00, distance: 0.00)
        case .places:
            PlaceSearch(index: 1)
        case .weather:
            WeatherUI()
        case .stacks:
            StacksView()
        case .contacts:
            InstagramHome()
        }
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
                Label(message, systemImage: "message")
                    .badge("NEW ITEMS!")
                    .listItemTint(themeColor)
            }
        }
    }
}

private struct DataSection: View {
    let themeColor: Color
    let customerService: CustomerServicing
    let customerFormService: CustomerFormServicing

    var body: some View {
        Section(header: Text("Data").foregroundColor(themeColor)) {
            NavigationLink("Leads") {
                CustomerUI(customerService: customerService, formService: customerFormService)
            }
            NavigationLink("Customers") {
                CustomerUI(customerService: customerService, formService: customerFormService)
            }
            NavigationLink("Vendors") { GradientUI() }
            NavigationLink("Employee") { GradientTextUI() }
            NavigationLink("To Do") { ListView() }
        }
    }
}

private struct OutgoingSection: View {
    let themeColor: Color
    let onSelectRoute: (MainMenuUI.ActiveRoute) -> Void

    var body: some View {
        Section(header: Text("Outgoing").foregroundColor(themeColor)) {
            Button("Geotify") { onSelectRoute(.geotify) }
            Button("Search Places") { onSelectRoute(.places) }
            Button("Weather") { onSelectRoute(.weather) }
            Button("Stacks") { onSelectRoute(.stacks) }
            Button("Contacts") { onSelectRoute(.contacts) }
        }
        .foregroundColor(.primary)
    }
}

// MARK: - Preview
@available(iOS 16.0, *)
struct MainMenuUI_Previews: PreviewProvider {
    static var previews: some View {
        MainMenuUI(onSignOut: { })
            .preferredColorScheme(.dark)
    }
}

// MARK: - Header
struct MainTopView: View {
    private enum Layout {
        static let height: CGFloat = 115
        static let cornerRadius: CGFloat = 10
        static let titleSize: CGFloat = 32
    }

    @AppStorage("color") private var color: Int?
    @AppStorage(SettingsUI.isCompanyNameKey) private var companyName: String = "Main Menu"
    @AppStorage(SettingsUI.backend) private var backEnd: String = "None"

    private var themeColor: Color {
        color == 0 ? .purple : .orange
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
        statusRow(title: "Weather:", value: "Cloudy", systemImage: "cloud.sun.fill")
            .padding(.bottom, 15)
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
        .font(.footnote.bold())
        .padding(.horizontal)
    }
}
