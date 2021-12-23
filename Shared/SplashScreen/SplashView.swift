//
//  ContentView.swift
//  Shared
//
//  Created by Peter Balsamo on 6/14/21.
//

import SwiftUI


struct SplashView: View {
    var body: some View {
        
        SplashScreen(imageSize: CGSize(width: 128, height: 128)) {
            
            SplashHome()
            
        } titleView: {
            
            Text("TheLight")
                .font(.system(size: 35).bold())
                .foregroundColor(.white)
            
        } logoView: {
            
            Image("taylor_swift_profile")
                .resizable()
                .aspectRatio(contentMode: .fit)
        } navButtons: {
            
            Button {
                
            } label: {
                Image("taylor_swift_profile")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 35, height: 35)
                    .clipShape(Circle())
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
