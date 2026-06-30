//
//  ContentView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI

// MARK: - Root Content
struct ContentView: View {
    @State private var session: SessionViewModel
    @State private var selection: RootTab = .home

    private let dependencies: AppDependencies

    init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        _session = State(
            initialValue: SessionViewModel(sessionService: dependencies.sessionService)
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
            Divider()
            TabBarView(selection: $selection)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .fullScreenCover(isPresented: $session.isLoginPresented) {
            LoginView(
                loginService: dependencies.makeLoginService(),
                authenticationService: dependencies.makeAuthenticationService(),
                locationCaptureManager: dependencies.makeLocationCaptureManager(),
                didCompleteLoginProcess: session.handleLoginCompleted
            )
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        selectedTabContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var selectedTabContent: some View {
        switch selection {
        case .home:
            MainMenuUI(
                onSignOut: session.signOut,
                makeCustomerService: dependencies.makeCustomerService,
                makeCustomerFormService: dependencies.makeCustomerFormService,
                makeWeatherManager: dependencies.makeWeatherManager,
                makeWeatherLocationProvider: dependencies.makeWeatherLocationProvider,
                appBadgeManager: dependencies.appBadgeManager
            )
        case .chat:
            MainMessagesView(
                isAuthenticated: session.isAuthenticated,
                onSignOut: session.signOut,
                repository: dependencies.makeChatRepository(),
                chatLogRepository: dependencies.makeChatRepository(),
                makeChatRepository: dependencies.makeChatRepository
            )
        case .ToDo:
            ListView()
        case .Expense:
            if #available(iOS 18.0, *) {
                NavigationStack {
                    ExpenseTrackerView()
                }
                .expenseModelContainer()
            } else {
                Text("Requires iOS 18")
            }
        case .web:
            WebUI()
        case .twitter:
            if #available(iOS 18.0, *) {
                TwitterUI()
            } else {
                Text("Requires iOS 18")
            }
        }
    }
}

// MARK: - Root Tabs
private enum RootTab: CaseIterable, Identifiable {
    case home
    case chat
    case ToDo
    case Expense
    case web
    case twitter

    static var visibleTabs: [RootTab] {
        #if DEBUG
        return allCases
        #else
        return [.home, .chat, .ToDo]
        #endif
    }

    var id: Self { self }

    var image: String {
        switch self {
        case .home: return "house.fill"
        case .chat: return "message.fill"
        case .ToDo: return "wave.3.left"
        case .Expense: return "dollarsign.circle"
        case .web: return "network"
        case .twitter: return "brain.head.profile"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .chat: return "Chat"
        case .ToDo: return "To Do"
        case .Expense: return "Expense"
        case .web: return "Web"
        case .twitter: return "Tweet"
        }
    }
}

// MARK: - Tab Bar
private struct TabBarView: View {
    @Binding var selection: RootTab
    @Namespace private var currentTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(RootTab.visibleTabs) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selection == tab,
                    namespace: currentTab
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selection = tab
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 6, leading: 8, bottom: 8, trailing: 8))
        .background(.ultraThinMaterial)
    }
}

private struct TabBarItem: View {
    let tab: RootTab
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                selectionIndicator

                Image(systemName: tab.image)
                    .font(.caption)
                    .frame(height: 18)

                Text(tab.label)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if isSelected {
            Capsule()
                .fill(Color.primary)
                .matchedGeometryEffect(id: "currentTab", in: namespace)
                .frame(width: 24, height: 3)
        } else {
            Capsule()
                .fill(Color.clear)
                .frame(width: 24, height: 3)
        }
    }
}

// MARK: - Previews
#Preview("Content - Dark") {
    ContentView(dependencies: .preview)
        .preferredColorScheme(.dark)
}

@available(iOS 18.0, *)
#Preview("Tab Bar - Dark", traits: .sizeThatFitsLayout) {
    TabBarView(selection: .constant(.home))
        .preferredColorScheme(.dark)
}

