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
    case chart

    var id: Self { self }
}

enum MainMenuDataRoute: Hashable {
    case leads
    case customers
    case vendors
    case employee
    case expenses
    case tip
    case steps
    case chart
}

@MainActor
struct MainMenuCoordinator {
    let makeCustomerService: () -> CustomerServicing
    let makeCustomerFormService: () -> CustomerFormServicing
    let makeWeatherManager: () -> WeatherManaging
    let makeWeatherLocationProvider: () -> WeatherLocationProviding
    let appBadgeManager: AppBadgeManaging
    let dismissSheet: () -> Void

    @ViewBuilder
    func sheetContent(_ sheet: MainMenuSheet) -> some View {
        switch sheet {
        case .modal(let modal):
            modalContent(modal)
        case .email:
            MailView(
                content: .theLightSupport(),
                onResult: { _ in dismissSheet() }
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
        case .leads:
            WaveUI()
        case .customers:
            CustomerUI(
                customerService: makeCustomerService(),
                formService: makeCustomerFormService(),
                appBadgeManager: appBadgeManager
            )
        case .vendors:
            SpotifyUI()
        case .employee:
            GlassMorphism()
        case .expenses:
            if #available(iOS 17.0, *) {
                ExpenseTrackerView()
                    .expenseModelContainer()
            } else {
                Text("Expenses require iOS 17 or later.")
            }
        case .tip:
            TipUI()
        case .steps:
            StepsTodayView()
        case .chart:
            ChartView()
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
            StacksView()
        case .instagram:
            InstagramHome()
        case .chart:
            ChartView()
        }
    }
}
