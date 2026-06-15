//
//  SideMenuBTN.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/17/22.
//

import SwiftUI

struct SideMenuBtn: View {
    
    var image: String
    var title: String
    
    @Binding var selectedTab: String
    var animation: Namespace.ID
    
    var body: some View {
        
        Button {
            
            withAnimation(.spring()) {
                self.selectedTab = image
            }
            
        } label: {
            
            HStack(spacing: 10) {
                
                Image(systemName: image)
                    .frame(width: 30)
                    .font(.title2)
                
                Text(title)
                    .fontWeight(.semibold)
                
            }
            .foregroundColor(selectedTab == image ? Color("blue") : Color.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .frame(maxWidth: getRectUI().width - 170, alignment: .leading)
            .background(
                
                // Hero animation
                
                ZStack {
                    
                    if selectedTab == image {
                        Color.white.opacity(selectedTab == image ? 1 : 0)
                            .clipShape(CustomCorners(corners: [.topRight, .bottomRight], radius: 12))
                            .matchedGeometryEffect(id: "Tab", in: animation)
                    }
                    
                }
                
                
            )
            
        }
        
    }
}

@available(iOS 16.0, *)
struct SideMenuBtn_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dependencies: .preview)
    }
}
