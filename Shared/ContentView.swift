//
//  ContentView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI

// MARK: - Root Content
struct ContentView: View {
    @State private var selection: RootTab = .home
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
            Divider()
            TabBarView(selection: $selection)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    private var tabContent: some View {
        TabView(selection: $selection) {
            MainMenuUI()
                .tag(RootTab.home)
            MainMessagesView()
                .tag(RootTab.chat)
            WaveUI()
                .tag(RootTab.wave)
            FurnitureUI()
                .tag(RootTab.furniture)
            WebUI()
                .tag(RootTab.web)
            TwitterUI()
                .tag(RootTab.twitter)
        }
    }
}

// MARK: - Root Tabs
private enum RootTab: CaseIterable, Identifiable {
    case home
    case chat
    case wave
    case furniture
    case web
    case twitter

    var id: Self { self }

    var image: String {
        switch self {
        case .home: return "house.fill"
        case .chat: return "message.fill"
        case .wave: return "wave.3.left"
        case .furniture: return "cart"
        case .web: return "network"
        case .twitter: return "brain.head.profile"
        }
    }

    var label: String {
        switch self {
        case .home: return "Home"
        case .chat: return "Chat"
        case .wave: return "Wave"
        case .furniture: return "Furn"
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
            ForEach(RootTab.allCases) { tab in
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
            .foregroundColor(isSelected ? .primary : .secondary)
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
    ContentView()
        .preferredColorScheme(.dark)
}

@available(iOS 17.0, *)
#Preview("Tab Bar - Dark", traits: .sizeThatFitsLayout) {
    TabBarView(selection: .constant(.home))
        .preferredColorScheme(.dark)
}

