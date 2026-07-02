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
        VStack(spacing: 24) {
            weatherSymbol
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text("Welcome to the Weather App")
                    .font(.title.bold())
                Text("Share your current location to get the weather in your area.")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            LocationButton(.shareCurrentLocation) {
                requestLocation()
            }
            .symbolVariant(.fill)
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.white)
            .clipShape(Capsule())

            Text("Your location is only used to fetch the local forecast.")
                .font(.footnote)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var weatherSymbol: some View {
        let icon = Image(systemName: "cloud.sun.fill")
            .symbolRenderingMode(.multicolor)
            .font(.system(size: 72))
        if #available(iOS 17.0, *) {
            icon.symbolEffect(.pulse)
        } else {
            icon
        }
    }
}

#Preview {
    WelcomeView(requestLocation: {})
        .background(Color.background)
        .preferredColorScheme(.dark)
}
