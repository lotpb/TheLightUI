//
//  SideTabViewUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/10/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct SideTabViewUI: View {
    
    @State var selectedTab = "house.fill"
    @State var volume: CGFloat = 0.4
    @State var showSideBar = false
    
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
                TabButtonUI(image: "house.fill", selectedTab: $selectedTab)
                TabButtonUI(image: "safari.fill", selectedTab: $selectedTab)
                TabButtonUI(image: "mic.fill", selectedTab: $selectedTab)
                TabButtonUI(image: "clock.fill", selectedTab: $selectedTab)
            }
            .frame(height: getRectUI().height / 2.3)
            .padding(.top)
            
            Spacer(minLength: 50)
            
            Button(action: {
                volume = volume + 0.1 < 1.0 ? volume + 0.1 : 1.0
            }, label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2).foregroundColor(.white)
            })
            
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
            
            Button(action: {
                volume = volume - 0.1 > 0 ? volume - 0.1 : 0
            }, label: {
                Image(systemName: "speaker.wave.1.fill")
                    .font(.title2)
                    .foregroundColor(.white)
            })
            
            Button(action: {
                withAnimation(.easeIn) {
                    showSideBar.toggle()
                }
            }, label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.white)
                    .rotationEffect(.init(degrees: showSideBar ? -180 : 0))
                    .padding()
                    .background(Color.black)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            })
            .padding(.top,getRectUI().height < 750 ? 10 : 30)
            .padding(.bottom, getSafeAreaUI().bottom == 0 ? 15 : 0)
            .offset(x: showSideBar ? 0 : 100)
        }
        .frame(width: 80)
        .background(Color.black.ignoresSafeArea())
        .offset(x: showSideBar ? 0 : -100)
        .padding(.trailing, -100)
        //.padding(.trailing, showSideBar ? 0 : -100)
        .zIndex(1)
        
    }
}

struct SideTabViewUI_Previews: PreviewProvider {
    static var previews: some View {
        SpotifyUI()
            .preferredColorScheme(.dark)
    }
}

struct TabButtonUI: View {
    var image: String
    @Binding var selectedTab: String
    
    var body: some View {
        
        Button(action: {
            withAnimation{selectedTab = image}
        }, label: {
            Image(systemName: image)
                .font(.title)
                .foregroundColor(selectedTab == image ? .white : Color.secondary.opacity(0.6))
                .frame(maxHeight: .infinity)
        })
    }
}

