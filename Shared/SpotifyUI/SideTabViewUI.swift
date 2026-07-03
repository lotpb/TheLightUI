//
//  SideTabViewUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/10/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

enum SideTab: CaseIterable {
    case home, browse, voice, recents

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .browse: "safari.fill"
        case .voice: "mic.fill"
        case .recents: "clock.fill"
        }
    }

    var title: String {
        switch self {
        case .home: "Home"
        case .browse: "Browse"
        case .voice: "Voice"
        case .recents: "Recents"
        }
    }
}

struct SideTabViewUI: View {
    @Binding var showSideBar: Bool
    let viewModel: MainMessagesViewModel
    var bottomSafeAreaInset: CGFloat = 0
    @State private var selectedTab: SideTab = .home
    @State private var volume = 0.4

    var body: some View {
        Group {
            if showSideBar {
                sidebarContent
                    .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                collapsedHandle
                    .transition(.opacity)
            }
        }
        .frame(width: showSideBar ? 82 : 42, alignment: .leading)
        .animation(.snappy(duration: 0.35), value: showSideBar)
        .zIndex(1)
    }

    private var sidebarContent: some View {
        VStack(spacing: 18) {
            ProfileAvatarImage(urlString: viewModel.chatUser?.profileImageUrl)
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.24), lineWidth: 1))
                .padding(.top, 16)
            
            VStack(spacing: 10) {
                ForEach(SideTab.allCases, id: \.self) { tab in
                    TabButtonUI(tab: tab, selectedTab: $selectedTab) {
                        showSideBar = false
                    }
                }
            }
            .padding(.top, 8)
            
            Spacer(minLength: 24)
            
            volumeControls
            toggleButton
                .padding(.bottom, bottomPadding)
        }
        .frame(width: 82)
        .background(.black.opacity(0.26))
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
        }
    }

    private var collapsedHandle: some View {
        VStack {
            Spacer()

            toggleButton
                .padding(.bottom, bottomPadding)
        }
        .frame(width: 42)
    }

    // Lift the toggle off the screen edge on devices without a bottom safe area.
    private var bottomPadding: CGFloat {
        bottomSafeAreaInset == 0 ? 16 : 4
    }

    private var volumeControls: some View {
        VStack(spacing: 12) {
            Button {
                adjustVolume(by: 0.1)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .accessibilityLabel("Increase volume")

            GeometryReader { proxy in
                let height = proxy.size.height
                let progress = height * volume
                
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(.white.opacity(0.16))
                        .frame(width: 5)
                    Capsule()
                        .fill(SpotifyStyle.accent)
                        .frame(width: 5, height: progress)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(height: 96)
            .accessibilityElement()
            .accessibilityLabel("Volume")
            .accessibilityValue(volume.formatted(.percent.precision(.fractionLength(0))))
            
            Button {
                adjustVolume(by: -0.1)
            } label: {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .accessibilityLabel("Decrease volume")
        }
    }

    private var toggleButton: some View {
        Button {
            showSideBar.toggle()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(showSideBar ? 0 : 180))
                .frame(width: 42, height: 42)
                .background(.white.opacity(0.10), in: Circle())
        }
        .accessibilityLabel(showSideBar ? "Hide sidebar" : "Show sidebar")
    }
    
    private func adjustVolume(by amount: Double) {
        volume = min(max(volume + amount, 0), 1)
    }
}

#Preview("Side Tab - Dark") {
    SideTabPreviewContainer()
        .preferredColorScheme(.dark)
}

private struct SideTabPreviewContainer: View {
    @State private var showSideBar = true
    @State private var viewModel = MainMessagesViewModel()

    var body: some View {
        SideTabViewUI(showSideBar: $showSideBar, viewModel: viewModel)
    }
}

struct TabButtonUI: View {
    let tab: SideTab
    @Binding var selectedTab: SideTab
    let onSelect: () -> Void
    
    private var isSelected: Bool { selectedTab == tab }

    var body: some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                selectedTab = tab
                onSelect()
            }
        } label: {
            Image(systemName: tab.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.58))
                .frame(width: 48, height: 48)
                .background(isSelected ? SpotifyStyle.accent : .clear, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
