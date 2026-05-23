//
//  TwitterUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/8/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

@MainActor
struct TwitterUI: View {
    fileprivate enum Layout {
        static let headerHeight: CGFloat = 180
        static let navigationBleedHeight: CGFloat = 120
        static let collapsedHeaderOffset: CGFloat = 80
        static let tabBarPinOffset: CGFloat = 90
        static let profileImageSize: CGFloat = 75
        static let compactProfileImageSize: CGFloat = 55
        static let maxContentWidth: CGFloat = 700
        static let tweetImageHeight: CGFloat = 250
    }

    private let tabs = ["Tweets", "Tweets & Likes", "Media", "Likes"]

    @Environment(\.colorScheme) private var colorScheme
    @State private var offset: CGFloat = 0
    @State private var currentTab = "Tweets"
    @State private var tabBarOffset: CGFloat = 0
    @Namespace private var animation
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false, content: {
            VStack(spacing: 15) {
                GeometryReader { proxy in
                    let minY = proxy.frame(in: .global).minY
                    ZStack {
                        headerGradient
                        //Text("TheLight")
                        @AppStorage(SettingsUI.isCompanyNameKey) var companyName: String = "Main Menu"
                        Text(companyName).font(.system(size: 40, weight: .heavy))
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                            .padding(.top, 40)
                        
                        BlurViewUI(style: .systemChromeMaterialDark)
                            .opacity(blurViewOpacity())
                    }
                    .clipped()
                    .frame(height: minY > 0 ? Layout.headerHeight + minY : nil)
                    .offset(y: minY > 0 ? -minY : -minY < Layout.collapsedHeaderOffset ? 0 : -minY - Layout.collapsedHeaderOffset)
                    .onAppear {
                        offset = minY
                    }
                    .onChange(of: minY) { newValue in
                        offset = newValue
                    }
                }
                .frame(height: Layout.headerHeight)
                .zIndex(1)
                
                VStack {
                    HStack {
                        Image("taylor_swift_profile")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: Layout.profileImageSize, height: Layout.profileImageSize)
                            .clipShape(Circle())
                            .padding(8)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .clipShape(Circle())
                            .offset(y: offset < 0  ? getOffset() - 20 : -20)
                            .scaleEffect(getScale())
                        
                        Spacer()
                        
                        Button {
                        } label: {
                            Text("Edit Profile")
                                .foregroundColor(.indigo)
                                .padding(.vertical, 10)
                                .padding(.horizontal)
                                .background(
                                    Capsule()
                                        .stroke(Color.indigo, lineWidth: 1.5)
                                )
                        }
                    }
                    .padding(.top, -25)
                    .padding(.bottom, -10)
                    
                    VStack(alignment: .leading, spacing: 8, content: {
                        Text("TheLight")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("@_thelight")
                            .foregroundColor(.secondary)
                        
                        Text("TheLight is a channel where i make videos on SwiftUI Website: https://TheLight.dev, Patreon: http://patreon.com/TheLight")
                        
                        HStack(spacing: 5) {
                            Text("13")
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Followers")
                                .foregroundColor(.secondary)
                            
                            Text("680")
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.leading, 10)
                            
                            Text("Following")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)
                    })
                    
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(tabs, id: \.self) { tab in
                                    TabButton(title: tab, currentTab: $currentTab, animation: animation)
                                }
                            }
                        }
                        
                        Divider()
                    }
                    .padding(.top, 30)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .offset(y: tabBarOffset < Layout.tabBarPinOffset ? -tabBarOffset + Layout.tabBarPinOffset : 0)
                    .overlay(
                        GeometryReader { reader in
                            let minY = reader.frame(in: .global).minY
                            Color.clear
                                .onAppear {
                                    tabBarOffset = minY
                                }
                                .onChange(of: minY) { newValue in
                                    tabBarOffset = newValue
                                }
                        }
                            .frame(width: 0, height: 0)
                        ,alignment: .top
                    )
                    .zIndex(1)
                    
                    VStack(spacing: 18) {
                        TweetView(tweet: "New iPhone 12 Purple Review By iJustine 🥳🥳🥳🥳.......", tweetImage: "ZuckBuddist")
                        
                        Divider()
                        
                        ForEach(1...20, id: \.self) { _ in
                            TweetView(tweet: TweetView.sampleText)
                            Divider()
                        }
                    }
                    .padding(.top)
                    .zIndex(0)
                }
                .padding(.horizontal)
                .zIndex(-offset > Layout.collapsedHeaderOffset ? 0 : 1)
            }
            //.preferredColorScheme(.light)
            .background(colorScheme == .dark ? Color.black : Color.white)
        })
            .frame(maxWidth: Layout.maxContentWidth)
            .background(alignment: .top) {
                headerGradient
                    .frame(height: Layout.headerHeight + Layout.navigationBleedHeight)
                    .ignoresSafeArea(edges: .top)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .ignoresSafeArea(.all, edges: .top)
    }

    private var headerGradient: some View {
        RadialGradient(
            gradient: Gradient(colors: [Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)), Color(#colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1))]),
            center: .center,
            startRadius: 5,
            endRadius: 500
        )
    }
    
    private func getOffset() -> CGFloat {
        let progress = (-offset / Layout.collapsedHeaderOffset) * 20
        return min(progress, 20)
    }
    
    private func getScale() -> CGFloat {
        let progress = -offset / Layout.collapsedHeaderOffset
        let scale = 1.8 - min(progress, 1)
        return min(scale, 1)
    }
    
    private func blurViewOpacity() -> Double {
        let progress = -(offset + Layout.collapsedHeaderOffset) / 150
        return Double(-offset > Layout.collapsedHeaderOffset ? progress : 0)
    }
}

@available(iOS 17.0, *)
#Preview("Twitter UI") {
    TwitterUI()
}

struct TabButton: View {
    
    let title: String
    @Binding var currentTab: String
    let animation: Namespace.ID
    
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentTab = title
            }
        } label: {
            LazyVStack(spacing: 12) {
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(currentTab == title ? .blue : .secondary)
                    .padding(.horizontal)
                if currentTab == title {
                    Capsule()
                        .fill(Color.blue)
                        .frame( height: 1.2)
                        .matchedGeometryEffect(id: "TAB", in: animation)
                }
                else {
                    Capsule()
                        .fill(Color.clear)
                        .frame( height: 1.2)
                }
            }
        }
    }
}

struct TweetView: View {
    static let sampleText = "Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, graphic or web designs. The passage is attributed to an unknown typesetter in the 15th century who is thought to have scrambled parts of Cicero's De Finibus Bonorum et Malorum for use in a type specimen book."
    
    let tweet: String
    let tweetImage: String?
    
    init(tweet: String, tweetImage: String? = nil) {
        self.tweet = tweet
        self.tweetImage = tweetImage
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 10, content: {
            Image("taylor_swift_profile")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: TwitterUI.Layout.compactProfileImageSize, height: TwitterUI.Layout.compactProfileImageSize)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 10, content: {
                (
                    Text("Kavsoft  ")
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    +
                    
                    Text("@_Kavsoft")
                        .foregroundColor(.secondary)
                )
                
                Text(tweet)
                    .frame(maxHeight: 100, alignment: .top)
                if let image = tweetImage {
                    GeometryReader { proxy in
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: proxy.size.width, height: TwitterUI.Layout.tweetImageHeight)
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                    .frame(height: TwitterUI.Layout.tweetImageHeight)
                }
            })
        })
    }
}

