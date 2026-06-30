//
//  ContentView.swift
//  Shared
//
//  Created by Peter Balsamo on 6/14/21.
//

import SwiftUI

struct SplashView: View {
    @State private var showProfile = false
    
    private let logoSize = CGSize(width: 128, height: 128)
    private let profileImageName = "taylor_swift_profile"
    
    var body: some View {
        SplashScreen(imageSize: logoSize) {
            SplashHome()
        } titleView: {
            Text("TheLight")
                .font(.system(size: 35).bold())
                .foregroundStyle(.white)
        } logoView: {
            Image(profileImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } navButtons: {
            Button {
                showProfile.toggle()
            } label: {
                Image(profileImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Profile")
        }
        .sheet(isPresented: $showProfile) {
            UserFormUI()
        }
    }
}

#Preview("Splash - Dark") {
    SplashView()
        .preferredColorScheme(.dark)
}
