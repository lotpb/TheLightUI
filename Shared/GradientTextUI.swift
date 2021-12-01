//
//  GradientTextUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/23/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct GradientTextUI: View {
    
    let text = Text("SwiftUI is a good tool for Designers")
        .font(.largeTitle.bold())
    
    var body: some View {
        
        VStack {
            text
                .foregroundColor(Color.clear)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [.orange, .red, .purple, .blue]),
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                    .mask(text))
                .padding(16)
            
            VStack {
                Text("App of the day")
                    .font(.title).bold()
                    .foregroundColor(.white)
                    .shadow(radius: 20)
            }
            .frame(width: 300, height: 400)
            .background(Color("pink2"))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            .shadow(color: Color("pink2").opacity(0.3), radius: 20, x: 0, y: 10)
        }
    }
}

struct GradientTextUI_Previews: PreviewProvider {
    static var previews: some View {
        GradientTextUI()
            
    }
}
