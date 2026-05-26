//
//  SideTabViewUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/10/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct SideTabViewUI: View {
    @State private var selectedTab = "house.fill"
    @State private var volume: CGFloat = 0.4
    @State private var showSideBar = true
    
    private let tabs = ["house.fill", "safari.fill", "mic.fill", "clock.fill"]
    
    var body: some View {
        VStack(spacing: 18) {
            Image("taylor_swift_profile")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 46, height: 46)
                .clipShape(Circle())
                .overlay(Circle().stroke(.white.opacity(0.24), lineWidth: 1))
                .padding(.top, 16)
            
            VStack(spacing: 10) {
                ForEach(tabs, id: \.self) { tab in
                    TabButtonUI(image: tab, selectedTab: $selectedTab)
                }
            }
            .padding(.top, 8)
            
            Spacer(minLength: 24)
            
            volumeControls
            toggleButton
        }
        .frame(width: 82)
        .background(.black.opacity(0.26))
        .background(.ultraThinMaterial)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(width: 1)
        }
        .offset(x: showSideBar ? 0 : -82)
        .padding(.trailing, showSideBar ? 0 : -82)
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: showSideBar)
        .zIndex(1)
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
        .padding(.bottom, getSafeAreaUI().bottom == 0 ? 16 : 4)
    }
    
    private func adjustVolume(by amount: CGFloat) {
        volume = min(max(volume + amount, 0), 1)
    }
}

#Preview("Side Tab - Dark") {
    SideTabViewUI()
        .preferredColorScheme(.dark)
}

struct TabButtonUI: View {
    let image: String
    @Binding var selectedTab: String
    
    private var isSelected: Bool { selectedTab == image }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                selectedTab = image
            }
        } label: {
            Image(systemName: image)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.58))
                .frame(width: 48, height: 48)
                .background(isSelected ? SpotifyStyle.accent : .clear, in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(image)
    }
}
