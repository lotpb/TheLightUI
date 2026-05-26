//
//  SplashScreen.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/25/21.
//

import SwiftUI

struct SplashScreen<Content: View, Title: View, Logo: View, NavButton: View>: View {
    private let content: Content
    private let titleView: Title
    private let logoView: Logo
    private let navButton: NavButton
    private let imageSize: CGSize
    
    @State private var textAnimation = false
    @State private var endAnimation = false
    @State private var showNavButtons = false
    @Namespace private var animation
    
    init(
        imageSize: CGSize,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder titleView: @escaping () -> Title,
        @ViewBuilder logoView: @escaping () -> Logo,
        @ViewBuilder navButtons: @escaping () -> NavButton
    ) {
        self.content = content()
        self.titleView = titleView()
        self.logoView = logoView()
        self.navButton = navButtons()
        self.imageSize = imageSize
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                SplashHeaderBackground()

                titleView
                    .scaleEffect(endAnimation ? 0.75 : 1)
                    .offset(y: textAnimation ? -5 : 110)
                
                if !endAnimation {
                    logoView
                        .matchedGeometryEffect(id: "splashLogo", in: animation)
                        .frame(width: imageSize.width, height: imageSize.height)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .shadow(color: .black.opacity(0.18), radius: 22, x: 0, y: 12)
                }
                
                HStack {
                    navButton
                        .opacity(showNavButtons ? 1 : 0)
                    Spacer()
                    
                    if endAnimation {
                        logoView
                            .matchedGeometryEffect(id: "splashLogo", in: animation)
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                            .offset(y: -5)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: endAnimation ? 64 : nil)
            .zIndex(1)
            
            content
                .frame(height: endAnimation ? nil : 0)
                .zIndex(0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear(perform: startAnimation)
    }
    
    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring()) {
                textAnimation = true
            }
            
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 1, blendDuration: 1)) {
                endAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation {
                    showNavButtons = true
                }
            }
        }
    }
}

private struct SplashHeaderBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.47, green: 0.23, blue: 0.88),
                Color(red: 0.30, green: 0.20, blue: 0.72),
                Color(red: 0.16, green: 0.12, blue: 0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)
        }
        .ignoresSafeArea()
    }
}

#Preview("Splash Screen - Dark") {
    SplashView()
        .preferredColorScheme(.dark)
}
