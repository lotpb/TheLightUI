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
    @State private var showSideBar = false
    
    private let tabs = ["house.fill", "safari.fill", "mic.fill", "clock.fill"]
    
    var body: some View {
        VStack {
            Image("taylor_swift_profile")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 45, height: 45)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .padding(.top)
            
            VStack {
                ForEach(tabs, id: \.self) { tab in
                    TabButtonUI(image: tab, selectedTab: $selectedTab)
                }
            }
            .frame(height: getRectUI().height / 2.3)
            .padding(.top)
            
            Spacer(minLength: 50)
            
            Button {
                adjustVolume(by: 0.1)
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Increase volume")
            
            GeometryReader { proxy in
                let height = proxy.frame(in: .global).height
                let progress = height * volume
                
                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.5))
                        .frame(width: 4)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: 4, height: progress)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .padding(.vertical, 20)
            
            Button {
                adjustVolume(by: -0.1)
            } label: {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            .accessibilityLabel("Decrease volume")
            
            Button {
                withAnimation(.easeIn) {
                    showSideBar.toggle()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .rotationEffect(.init(degrees: showSideBar ? -180 : 0))
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .accessibilityLabel(showSideBar ? "Hide sidebar" : "Show sidebar")
            .padding(.top, getRectUI().height < 750 ? 10 : 30)
            .padding(.bottom, getSafeAreaUI().bottom == 0 ? 15 : 0)
            .offset(x: showSideBar ? 0 : 100)
        }
        .frame(width: 80)
        .background(Color.black.ignoresSafeArea())
        .offset(x: showSideBar ? 0 : -100)
        .padding(.trailing, -100)
        .zIndex(1)
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
    
    var body: some View {
        Button {
            withAnimation {
                selectedTab = image
            }
        } label: {
            Image(systemName: image)
                .font(.title)
                .foregroundColor(selectedTab == image ? .white : Color.secondary.opacity(0.6))
                .frame(maxHeight: .infinity)
        }
        .accessibilityLabel(image)
    }
}
