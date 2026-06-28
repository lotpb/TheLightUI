//
//  WelcomeView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/26/21.
//

import SwiftUI
import CoreLocationUI

struct WelcomeView: View {
    let requestLocation: () -> Void
    
    var body: some View {
        VStack {
            VStack(spacing: 20) {
                Text("Welcome to the Weather App")
                    .bold().font(.title)
                Text("Please share your current location to get the weather in your area")
                    .padding()
            }
            .multilineTextAlignment(.center)
            .padding()
            
            LocationButton(.shareCurrentLocation) {
                requestLocation()
            }
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .symbolVariant(.fill)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(requestLocation: {})
            .background(Color.background)
            .preferredColorScheme(.dark)
    }
}
