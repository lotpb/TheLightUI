//
//  SplashHome.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI


struct SplashHome: View {
    
    @State var currentTab = "All Photos"
    @Namespace var animation
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            HStack(spacing: 0) {
                
                TabButtonSplash(title: "All photos", animation: animation, currentTab: $currentTab)
                
                TabButtonSplash(title: "Chats", animation: animation, currentTab: $currentTab)
                
                TabButtonSplash(title: "Status", animation: animation, currentTab: $currentTab)
                
            }
            .padding(.top, 20)
            .background(Color.purple)
            
            ScrollView(.vertical, showsIndicators: false) {
                
                VStack(spacing: 15) {
                   
                    ForEach(1...6, id: \.self) { index in
                        
                        //Image("Post\(index)")
                        Image("taylor_swift_profile")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width - 30, height: 250)
                            .cornerRadius(8)
                    }
                }
                .padding(15)
            }
        }
        .background(.quaternary)
    }
}

struct SplashHome_Previews: PreviewProvider {
    static var previews: some View {
        SplashHome()
    }
}

struct TabButtonSplash: View {
    
    var title: String
    var animation: Namespace.ID
    @Binding var currentTab: String
    
    var body: some View {
        
        Button {
            withAnimation(.spring()) {
                currentTab = title
            }
        } label: {
            
            VStack {
                
                Text(title)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                ZStack {
                    
                    if currentTab == title {
                        Capsule()
                            .fill(.white)
                            .shadow(radius: 15)
                            .matchedGeometryEffect(id: "TAB", in: animation)
                            .frame(height: 3.5)
                    }
                    else {
                        Capsule()
                            .fill(.clear)
                            .frame(height: 3.5)
                    }
                }
            }
        }
        
    }
}
