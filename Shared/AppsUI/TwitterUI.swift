//
//  TwitterUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/8/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct TwitterUI: View {
    @Environment(\.colorScheme) var colorScheme
    @State var offset: CGFloat = 0
    @State var currentTab = "Tweets"
    @Namespace var animation
    @State var tabBarOffset: CGFloat = 0
    @State var titleOffset: CGFloat = 0
    let maxWidthForIpad: CGFloat = 700
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false, content: {
            VStack(spacing: 15) {
                GeometryReader{ proxy -> AnyView in
                    let minY = proxy.frame(in: .global).minY
                    DispatchQueue.main.async {
                        self.offset = minY
                    }
                    return AnyView(
                        ZStack {
                            RadialGradient(
                                gradient: Gradient(colors: [Color(#colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)), Color(#colorLiteral(red: 0.06274510175, green: 0, blue: 0.1921568662, alpha: 1))]),
                                center: .center,
                                startRadius: /*@START_MENU_TOKEN@*/5/*@END_MENU_TOKEN@*/,
                                endRadius: /*@START_MENU_TOKEN@*/500/*@END_MENU_TOKEN@*/)
                                .ignoresSafeArea()
                            
                            Text("TheLight Software")
                                .font(.title)
                                .fontWeight(.heavy)
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            BlurViewUI(style: .systemChromeMaterialDark)
                                .opacity(blurViewOpacity())
                        }
                            .clipped()
                            .frame(height: minY > 0 ? 180 + minY : nil)
                            .offset(y: minY > 0 ? -minY : -minY < 80 ? 0 : -minY - 80)
                    )
                }
                .frame(height: 180)
                .zIndex(1)
                
                VStack {
                    HStack {
                        Image("taylor_swift_profile")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 75, height: 75)
                            .clipShape(Circle())
                            .padding(8)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .clipShape(Circle())
                            .offset(y: offset < 0  ? getOffset() - 20 : -20)
                            .scaleEffect(getScale())
                        
                        Spacer()
                        
                        Button(action: {
                           //UserFormUI()
                        }, label: {
                            Text("Edit Profile")
                                .foregroundColor(.indigo)
                                .padding(.vertical,10)
                                .padding(.horizontal)
                                .background(Capsule()
                                .stroke(Color.indigo, lineWidth: 1.5))
                        })
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
                                TabButton(title: "Tweets", currentTab: $currentTab, animation: animation)
                                TabButton(title: "Tweets & Likes", currentTab: $currentTab, animation: animation)
                                TabButton(title: "Media", currentTab: $currentTab, animation: animation)
                                TabButton(title: "Likes", currentTab: $currentTab, animation: animation)
                            }
                        }
                        
                        Divider()
                    }
                    .padding(.top, 30)
                    .background(colorScheme == .dark ? Color.black : Color.white)
                    .offset(y: tabBarOffset < 90 ? -tabBarOffset + 90 : 0)
                    .overlay(
                        GeometryReader{reader -> Color in
                            let minY = reader.frame(in: .global).minY
                            DispatchQueue.main.async {
                                self.tabBarOffset = minY
                            }
                            return Color.clear
                        }
                            .frame(width: 0, height: 0)
                        ,alignment: .top
                    )
                    .zIndex(1)
                    
                    VStack(spacing: 18){
                        // Sample Tweets...
                        TweetView(tweet: "New iPhone 12 Purple Review By iJustine 🥳🥳🥳🥳.......", tweetImage: "ZuckBuddist")
                        
                        Divider()
                        
                        ForEach(1...20,id: \.self){_ in
                            TweetView(tweet: sampleText)
                            Divider()
                        }
                    }
                    .padding(.top)
                    .zIndex(0)
                }
                .padding(.horizontal)
                .zIndex(-offset > 80 ? 0 : 1)
            }
            //.preferredColorScheme(.light)
            //.background(colorScheme == .dark ? Color.black : Color.white)
        })
            .frame(maxWidth: maxWidthForIpad)
            .ignoresSafeArea(.all, edges: .top)
    }
    
    func getOffset()->CGFloat {
        let progress = (-offset / 80) * 20
        return progress <= 20 ? progress : 20
    }
    
    func getScale()->CGFloat {
        let progress = -offset / 80
        let scale = 1.8 - (progress < 1.0 ? progress : 1)
        return scale < 1 ? scale : 1
    }
    
    func blurViewOpacity()->Double {
        let progress = -(offset + 80) / 150
        return Double(-offset > 80 ? progress : 0)
    }
}

struct TwitterUI_Previews: PreviewProvider {
    static var previews: some View {
        TwitterUI()
    }
}

struct TabButton: View {
    
    var title: String
    @Binding var currentTab: String
    var animation: Namespace.ID
    
    var body: some View {
        Button {
            withAnimation {
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
    var tweet: String
    var tweetImage: String?
    
    var body: some View {
        //CustomColor.linenColor
        HStack(alignment: .top, spacing: 10, content: {
            Image("taylor_swift_profile")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 55, height: 55)
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
                    GeometryReader{proxy in
                        Image(image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: proxy.frame(in: .global).width, height: 250)
                            .cornerRadius(15)
                    }
                    .frame(height: 250)
                }
            })
        })
    }
}

var sampleText = "Lorem ipsum, or lipsum as it is sometimes known, is dummy text used in laying out print, graphic or web designs. The passage is attributed to an unknown typesetter in the 15th century who is thought to have scrambled parts of Cicero's De Finibus Bonorum et Malorum for use in a type specimen book."

