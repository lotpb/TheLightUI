//
//  SplashHome.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

struct SplashHome: View {
    @State private var currentTab = SplashTab.allPhotos.rawValue
    @Namespace private var animation
    
    private let photoIndexes = Array(1...6)
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(SplashTab.allCases) { tab in
                    TabButtonSplash(title: tab.rawValue, animation: animation, currentTab: $currentTab)
                }
            }
            .padding(.top, 20)
            .background(Color.purple)
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 15) {
                    ForEach(photoIndexes, id: \.self) { _ in
                        Image("taylor_swift_profile")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(15)
            }
        }
        .background(.quaternary)
    }
}

private enum SplashTab: String, CaseIterable, Identifiable {
    case allPhotos = "All photos"
    case chats = "Chats"
    case status = "Status"
    
    var id: String { rawValue }
}

#Preview("Splash Home - Dark") {
    SplashHome()
        .preferredColorScheme(.dark)
}

struct TabButtonSplash: View {
    let title: String
    let animation: Namespace.ID
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
                    } else {
                        Capsule()
                            .fill(.clear)
                            .frame(height: 3.5)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
