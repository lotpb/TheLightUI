//
//  GradientTextUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/23/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct GradientTextUI: View {
    var body: some View {
        VStack(spacing: 32) {
            GradientTitleText("SwiftUI is a good tool for designers")
                .padding(.horizontal, 24)

            FeatureCard()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

private struct GradientTitleText: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.largeTitle.bold())
            .multilineTextAlignment(.center)
            .foregroundStyle(
                LinearGradient(
                    colors: [.orange, .red, .purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct FeatureCard: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "star.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(radius: 12)

            Text("App of the day")
                .font(.title.bold())
                .foregroundStyle(.white)
                .shadow(radius: 20)

            Text("A compact gradient card with reusable SwiftUI styling.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(width: 300, height: 400)
        .background(
            LinearGradient(
                colors: [Color("pink2"), Color.purple.opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .shadow(color: Color("pink2").opacity(0.3), radius: 20, x: 0, y: 10)
    }
}
// MARK: - Preview
#Preview("Gradient Text") {
    GradientTextUI()
}

