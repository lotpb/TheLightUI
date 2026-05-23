//
//  ContentView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selection) {
                MainMenuUI()
                    .tag(0)
                MainMessagesView()
                    .tag(1)
                WaveUI()
                    .tag(2)
                FurnitureUI()
                    .tag(3)
                WebUI()
                    .tag(4)
                TwitterUI()
                    .tag(5)
            }
            Divider()
            TabBarView(selection: $selection)
        }
        .background(Color.red)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .ignoresSafeArea(.all, edges: .top)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}

struct TabBarView: View {
    @Binding var selection: Int
    @Namespace private var currentTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Self.tabs.indices, id: \.self) { index in
                tabButton(for: Self.tabs[index], at: index)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }
    
    private func tabButton(for tab: Tab, at index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selection = index
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if selection == index {
                        Capsule()
                            .fill(Color.primary)
                            .matchedGeometryEffect(id: "currentTab", in: currentTab)
                    } else {
                        Capsule()
                            .fill(Color.clear)
                    }
                }
                .frame(width: 24, height: 3)
                
                Image(systemName: tab.image)
                    .font(.caption)
                    .frame(height: 18)
                
                Text(tab.label)
                    .font(.system(size: 12, weight: selection == index ? .semibold : .regular))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundColor(selection == index ? .primary : .secondary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
    }
}

struct TabBarView_Previews: PreviewProvider {
    static var previews: some View {
        TabBarView(selection: Binding.constant(0))
            .previewLayout(.sizeThatFits)
            .preferredColorScheme(.dark)
    }
}

private struct Tab {
    let image: String
    let label: String
}

private extension TabBarView {
    static let tabs = [
        Tab(image: "house.fill", label: "Home"),
        Tab(image: "message.fill", label: "Chat"),
        Tab(image: "wave.3.left", label: "Wave"),
        Tab(image: "cart", label: "Furn"),
        Tab(image: "network", label: "Web"),
        Tab(image: "brain.head.profile", label: "Tweet"),
    ]
}
