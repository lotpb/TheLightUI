//
//  SideMenuUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/17/22.
//

import SwiftUI

struct SideMenuUI: View {
    
    @Binding var selectedTab: String
    @Namespace var animation
    
    var body: some View {
        
        // Side Menu
        VStack(alignment: .leading, spacing: 15) {
            
            // Profile
            Image("taylor_swift_profile")
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .cornerRadius(10)
                .padding(.top, 50)
            
            VStack(alignment: .leading, spacing: 6) {
                
                Text("Peter Balsamo")
                    .font(.title)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                
                Button {
                    
                    
                } label: {
                    
                    Text("View Profile")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .opacity(0.7)
                    
                }
                
                // tab Buttons
                VStack(alignment: .leading,spacing: 15) {
                    
                    SideMenuBtn(image: "house", title: "Home", selectedTab: $selectedTab, aimation: animation)
                    
                    SideMenuBtn(image: "clock.arrow.circlepath", title: "Histories", selectedTab: $selectedTab, aimation: animation)
                    
                    SideMenuBtn(image: "bell.badge", title: "Notifications", selectedTab: $selectedTab, aimation: animation)
                    
                    SideMenuBtn(image: "gearshape.fill", title: "Settings", selectedTab: $selectedTab, aimation: animation)
                    
                    SideMenuBtn(image: "questionmark.circle", title: "Help", selectedTab: $selectedTab, aimation: animation)
                    
                }
                .padding(.leading, -15)
                .padding(.top, 50)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                                            
                    SideMenuBtn(image: "arrow.right", title: "Log Out", selectedTab: .constant(""), aimation: animation)
                        .padding(.leading, -15)
                    
                    Text("App version 1.2.34")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .opacity(0.8)
                    
                }
                
            }
            
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        
    }
}
