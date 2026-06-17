//
//  MainMenuSections.swift
//  TheLightUI
//

import SwiftUI

struct IncomingSection: View {
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

struct DataSection: View {
    let themeColor: Color
    let onSelect: (MainMenuDataRoute) -> Void

    private var items: [DataMenuItem] {
        var items: [DataMenuItem] = [
            DataMenuItem(
                route: .leads,
                title: "Leads",
                subtitle: "Potential customers",
                systemImage: "person.crop.circle.badge.plus"
            ),
            DataMenuItem(
                route: .customers,
                title: "Customers",
                subtitle: "Active accounts",
                systemImage: "person.2.fill"
            )
        ]

        #if DEBUG
        items.append(contentsOf: [
            DataMenuItem(
                route: .vendors,
                title: "Vendors",
                subtitle: "Suppliers",
                systemImage: "shippingbox.fill"
            ),
            DataMenuItem(
                route: .employee,
                title: "Employee",
                subtitle: "Team directory",
                systemImage: "person.text.rectangle"
            )
        ])
        #endif

        if #available(iOS 17.0, *) {
            items.append(
                DataMenuItem(
                    route: .expenses,
                    title: "Expenses",
                    subtitle: "Track spending",
                    systemImage: "creditcard.fill"
                )
            )
        }

        return items
    }

    var body: some View {
        Section(header: Text("Data").foregroundColor(themeColor)) {
            ForEach(items) { item in
                MenuRouteButton(item: item, tint: themeColor) {
                    onSelect(item.route)
                }
            }
        }
    }
}

struct OutgoingSection: View {
    let themeColor: Color
    let onSelectRoute: (MainMenuFullscreenRoute) -> Void

    private var items: [FullscreenMenuItem] {
        var items: [FullscreenMenuItem] = [
            FullscreenMenuItem(
                route: .geotify,
                title: "Geotify",
                subtitle: "Region monitoring",
                systemImage: "mappin.and.ellipse"
            ),
            FullscreenMenuItem(
                route: .places,
                title: "Search Places",
                subtitle: "Find a place nearby",
                systemImage: "magnifyingglass.circle.fill"
            ),
            FullscreenMenuItem(
                route: .weather,
                title: "Weather",
                subtitle: "Forecast and conditions",
                systemImage: "cloud.sun.fill"
            )
        ]

        #if DEBUG
        items.insert(
            FullscreenMenuItem(
                route: .chart,
                title: "Chart",
                subtitle: "Analytics",
                systemImage: "chart.bar.fill"
            ),
            at: 0
        )
        items.append(contentsOf: [
            FullscreenMenuItem(
                route: .stacks,
                title: "Stacks",
                subtitle: "Layout demos",
                systemImage: "square.stack.3d.up.fill"
            ),
            FullscreenMenuItem(
                route: .instagram,
                title: "Instagram",
                subtitle: "Social feed",
                systemImage: "camera.circle.fill"
            )
        ])
        #endif

        return items
    }

    var body: some View {
        Section(header: Text("Outgoing").foregroundColor(themeColor)) {
            ForEach(items) { item in
                MenuRouteButton(item: item, tint: themeColor) {
                    onSelectRoute(item.route)
                }
            }
        }
        .foregroundColor(.primary)
    }
}

private struct DataMenuItem: Identifiable, MenuRouteDisplaying {
    let route: MainMenuDataRoute
    let title: String
    let subtitle: String?
    let systemImage: String

    var id: MainMenuDataRoute { route }
}

private struct FullscreenMenuItem: Identifiable, MenuRouteDisplaying {
    let route: MainMenuFullscreenRoute
    let title: String
    let subtitle: String?
    let systemImage: String

    var id: MainMenuFullscreenRoute { route }
}
