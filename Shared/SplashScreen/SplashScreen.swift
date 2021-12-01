//
//  SplashScreen.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/25/21.
//

import SwiftUI

struct SplashScreen<Content: View, Title: View, Logo: View, NavButton: View>: View {
    
    var content: Content
    var titleView: Title
    var logoView: Logo
    var navButton: NavButton
    
    var imageSize: CGSize
    
    init(imageSize: CGSize, @ViewBuilder content: @escaping () -> Content, @ViewBuilder titleView: @escaping () -> Title, @ViewBuilder logoView: @escaping () -> Logo, @ViewBuilder navButtons: @escaping() -> NavButton) {
        
        self.content = content()
        self.titleView = titleView()
        self.logoView = logoView()
        self.navButton = navButtons()
        
        self.imageSize = imageSize
    }
    
    @State var textAnimation = false
    @State var imageAnimation = false
    @State var endAnimation = false
    
    @State var showNavButtons = false
    
    @Namespace var animation
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            ZStack {
                
                //Color(.purple)
                    //.background(Color.purple)
                
                titleView
                    .scaleEffect(endAnimation ? 0.75 : 1)
                    .offset(y: textAnimation ? -5 : 110)
                
                if !endAnimation {
                    logoView
                        .matchedGeometryEffect(id: "taylor_swift_profile", in: animation)
                        .frame(width: imageSize.width, height: imageSize.height)
                }
                
                HStack {
                    navButton
                        .opacity(showNavButtons ? 1 : 0)
                    Spacer()
                    
                    if endAnimation {
                        logoView
                            .matchedGeometryEffect(id: "taylor_swift_profile", in: animation)
                            .frame(width: 30, height: 30)
                            .offset(y: -5)
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: endAnimation ? 60 : nil)
            .zIndex(1)
            
            .background(Color.purple.ignoresSafeArea()) //added
            
            content
                .frame(height: endAnimation ? nil: 0)
                .zIndex(0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onAppear {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                
                withAnimation(.spring()) {
                    
                    textAnimation.toggle()
                }
                
                withAnimation(Animation.interactiveSpring(response: 0.6, dampingFraction: 1, blendDuration: 1)) {
                    
                    endAnimation.toggle()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    withAnimation {
                        showNavButtons.toggle()
                    }
                }
            }
        }
    }
}

@available(iOS 15.0, *)
struct SplashScreen_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
