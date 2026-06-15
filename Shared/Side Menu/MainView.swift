//
//  MainView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/17/22.
//

import SwiftUI

struct MainView: View {
    
    @State private var selectedTab = "house"
    @State private var showMenu = false
    
    var body: some View {
        
        ZStack {
            
            Color.blue
                .ignoresSafeArea()
            
            SideMenuUI(selectedTab: $selectedTab)
            
            ZStack {
                
                // two background cards...
                
                Color.white
                    .opacity(0.5)
                    .cornerRadius(showMenu ? 15 : 0)
                    .shadow(color: .black.opacity(0.07), radius: 5, x: -5, y: 0)
                    .offset(x: showMenu ? -25 : 0)
                    .padding(.vertical, 25)
                
                Color.white
                    .opacity(0.5)
                    .cornerRadius(showMenu ? 15 : 0)
                    .shadow(color: .black.opacity(0.07), radius: 5, x: -5, y: 0)
                    .offset(x: showMenu ? -50 : 0)
                    .padding(.vertical, 60)
                
                Home(selectedTab: $selectedTab)
                    .cornerRadius(showMenu ? 15 : 0)
                
            }
            .scaleEffect(showMenu ? 0.84 : 1)
            .offset(x: showMenu ? getRectUI().width - 120 : 0)
            .ignoresSafeArea()
            .overlay(
                
                Button {
                    
                    withAnimation(.spring()) {
                        showMenu.toggle()
                    }
                    
                } label: {
                    
                    // Animated drawer button.
                    VStack(spacing: 5){
                        
                        Capsule()
                            .fill(showMenu ? Color.white : Color.primary)
                            .frame(width: 30, height: 3)
                        // Rotating...
                            .rotationEffect(.init(degrees: showMenu ? -50 : 0))
                            .offset(x: showMenu ? 2 : 0, y: showMenu ? 9 : 0)

                        VStack(spacing: 5){
                            
                            Capsule()
                                .fill(showMenu ? Color.white : Color.primary)
                                .frame(width: 30, height: 3)
                            // Moving Up when clicked...
                            Capsule()
                                .fill(showMenu ? Color.white : Color.primary)
                                .frame(width: 30, height: 3)
                                .offset(y: showMenu ? -8 : 0)
                        }
                        .rotationEffect(.init(degrees: showMenu ? 50 : 0))
                    }
                    .contentShape(Rectangle())
                    
                }
                .padding()
                
                ,alignment: .topLeading
            
            )
        }
        
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}

