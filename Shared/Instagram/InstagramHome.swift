//
//  InstagramHome.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI

@available(iOS 15.0, *)
struct InstagramHome: View {
    @State private var currentTab = InstagramTab.reels.rawValue
    @Environment(\.dismiss) private var dismiss
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                TabView(selection: $currentTab) {
                    Text("Home")
                        .tag(InstagramTab.home.rawValue)
                    
                    Text("Search")
                        .tag(InstagramTab.search.rawValue)
                    
                    ReelsView()
                        .tag(InstagramTab.reels.rawValue)
                    
                    Text("Liked")
                        .tag(InstagramTab.liked.rawValue)
                    
                    Text("Profile")
                        .tag(InstagramTab.profile.rawValue)
                }
                
                HStack(spacing: 0) {
                    ForEach(InstagramTab.allCases) { tab in
                        TabBarBtn(tab: tab, currentTab: $currentTab)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .overlay(Divider(), alignment: .top)
                .background(currentTab == InstagramTab.reels.rawValue ? .black : .clear)
            }
            
            // Close button top-right
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(currentTab == InstagramTab.reels.rawValue ? .white : .primary)
                    .padding(12)
            }
            .accessibilityLabel("Close")
        }
    }
}

private enum InstagramTab: String, CaseIterable, Identifiable {
    case home = "house.fill"
    case search = "magnifyingglass"
    case reels = "film"
    case liked = "suit.heart"
    case profile = "person.circle"
    
    var id: String { rawValue }
}

@available(iOS 15.0, *)
#Preview("Instagram - Dark") {
    InstagramHome()
        .preferredColorScheme(.dark)
}


private struct TabBarBtn: View {
    let tab: InstagramTab
    @Binding var currentTab: String
    
    var body: some View {
        Button {
            withAnimation {
                currentTab = tab.rawValue
            }
        } label: {
            Image(systemName: tab.rawValue)
                .font(.title2)
                .foregroundColor(currentTab == tab.rawValue ? selectedColor : .secondary)
                .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(tab.rawValue)
    }
    
    private var selectedColor: Color {
        currentTab == InstagramTab.reels.rawValue ? .white : .primary
    }
}
