//
//  MainMenuCoordinator.swift
//  TheLightUI
//

import SwiftUI

enum MainMenuModal: Hashable {
    case about
    case settings
    case directions
    case users
    case membership
}

enum MainMenuSheet: Identifiable {
    case modal(MainMenuModal)
    case email

    var id: String {
        switch self {
        case .modal(let modal): return "modal_\(modal)"
        case .email: return "email"
        }
    }
}

enum MainMenuFullscreenRoute: Identifiable {
    case geotify
    case places
    case weather
    case stacks
    case instagram
    case tweet
    case chart
    case chat

    var id: Self { self }
}

enum MainMenuDataRoute: Hashable {
    case snapshot
    case leads
    case customers
    case vendors
    case employee
    case expenses
    case tip
    case steps
    case chart
    case todo
}

@MainActor
struct MainMenuCoordinator {
    let customerStore: CustomerStore
    let makeCustomerFormService: () -> CustomerFormServicing
    let makeWeatherManager: () -> WeatherManaging
    let makeWeatherLocationProvider: () -> WeatherLocationProviding
    let appBadgeManager: AppBadgeManaging
    let isAuthenticated: Bool
    let onSignOut: () -> Void

    // `dismiss` is passed at the call site so the coordinator itself never
    // captures a closure over mutable view state.
    @ViewBuilder
    func sheetContent(_ sheet: MainMenuSheet, dismiss: @escaping () -> Void) -> some View {
        switch sheet {
        case .modal(let modal):
            modalContent(modal)
        case .email:
            MailView(
                content: .theLightSupport(),
                onResult: { _ in dismiss() }
            )
        }
    }

    @ViewBuilder
    func modalContent(_ modal: MainMenuModal) -> some View {
        switch modal {
        case .about:
            GradientUI()
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

    @ViewBuilder
    func dataDestination(_ route: MainMenuDataRoute) -> some View {
        switch route {
        case .snapshot:
            SnapshotView()
        case .leads:
            CustomerUI(
                viewModel: customerStore,
                formService: makeCustomerFormService(),
                appBadgeManager: appBadgeManager,
                categoryFilter: .lead
            )
        case .customers:
            CustomerUI(
                viewModel: customerStore,
                formService: makeCustomerFormService(),
                appBadgeManager: appBadgeManager,
                categoryFilter: .customer
            )
        case .vendors:
            CustomerUI(
                viewModel: customerStore,
                formService: makeCustomerFormService(),
                appBadgeManager: appBadgeManager,
                categoryFilter: .vendor
            )
        case .employee:
            CustomerUI(
                viewModel: customerStore,
                formService: makeCustomerFormService(),
                appBadgeManager: appBadgeManager,
                categoryFilter: .employee
            )
        case .expenses:
            ExpenseTrackerView()
                .expenseModelContainer()
        case .tip:
            TipUI()
        case .steps:
            StepsTodayView()
        case .chart:
            ChartView(customerStore: customerStore)
        case .todo:
            ListView()
        }
    }

    @ViewBuilder
    func fullscreenDestination(_ route: MainMenuFullscreenRoute) -> some View {
        switch route {
        case .geotify:
            MapUI(mode: .currentLocation, travelTime: 0.00, distance: 0.00)
        case .places:
            PlaceSearch(index: 1)
        case .weather:
            WeatherUI(
                apiManager: makeWeatherManager(),
                locationManager: makeWeatherLocationProvider()
            )
        case .stacks:
            StacksView(customerStore: customerStore)
        case .instagram:
            InstagramHome()
        case .tweet:
            TwitterUI()
        case .chart:
            // ChartView no longer owns a NavigationStack (it can be pushed
            // from the main menu), so standalone presentation wraps it here.
            NavigationStack {
                ChartView(customerStore: customerStore)
            }
        case .chat:
            MainMessagesView(
                isAuthenticated: isAuthenticated,
                onSignOut: onSignOut
            )
        }
    }
}
