//
//  InstagramHome.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI

@available(iOS 15.0, *)
struct InstagramHome: View {
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    
    @State var currentTab = "Reels"
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            TabView(selection: $currentTab) {
                
                Text("Home")
                    .tag("house.fill")
                
                Text("Search")
                    .tag("magnifyingglass")
                
                ReelsView()
                    .tag("film")
                
                Text("Liked")
                    .tag("suit.heart")
                
                Text("Profile")
                    .tag("person.circle")
            }
            
            HStack(spacing: 0) {
                
                ForEach (
                    ["house.fill", "magnifyingglass", "film", "suit.heart", "person.circle"], id: \.self) {image in
                    
                    TabBarBtn(image: image, isSystemImage: image != "Reels", currentTab: $currentTab)
                    
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .overlay(Divider(), alignment: .top)
            .background(currentTab == "Reels" ? .black : .clear)
        }
    }
}

@available(iOS 15.0, *)
struct InstagramHome_Previews: PreviewProvider {
    static var previews: some View {
        InstagramHome()
    }
}

struct TabBarBtn: View {
    
    var image: String
    var isSystemImage: Bool
    @Binding var currentTab: String
    
    var body: some View {
        
        Button {
            withAnimation {currentTab = image}
        } label: {
            
            ZStack {
                
                if isSystemImage {
                    Image(systemName: image)
                        .font(.title2)
                }
                else {
                    Image(image)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 25, height: 25)
                }
            }
            .foregroundColor(currentTab == image ? currentTab == "Reels" ? .white : .primary : .gray)
            .frame(maxWidth: .infinity)
        }
        
    }
}
