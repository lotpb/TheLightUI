//
//  GlassMorphism.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/25/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct GlassMorphism: View {
    var body: some View {
        ZStack {
            GlassBackground()
            GlassCard()
        }
        .ignoresSafeArea()
    }
}

struct GlassMorphism_Previews: PreviewProvider {
    static var previews: some View {
        GlassMorphism()
    }
}

private struct GlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.88, blue: 0.96),
                    Color(red: 0.78, green: 0.79, blue: 0.86)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.blue.opacity(0.45),
                    Color.purple.opacity(0.30),
                    Color.white.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.overlay)

            VStack(spacing: 0) {
                Color.white.opacity(0.18)
                    .frame(height: 180)
                    .blur(radius: 30)

                Spacer()

                Color.indigo.opacity(0.24)
                    .frame(height: 220)
                    .blur(radius: 34)
            }
        }
    }
}

private struct GlassCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("TheLight Software")
                        .font(.system(size: 24, weight: .bold, design: .rounded))

                    Text("Glass interface study")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .foregroundColor(.white.opacity(0.75))
                }
            }

            Text("A translucent card layered over soft color and blur, built with reusable SwiftUI views.")
                .font(.footnote)
                .lineSpacing(4)
                .foregroundColor(.white.opacity(0.82))

            HStack(spacing: 10) {
                GlassMetricView(value: "24", title: "Screens")
                GlassMetricView(value: "8", title: "Styles")
                GlassMetricView(value: "3", title: "Themes")
            }
        }
        .padding(24)
        .frame(width: 320)
        .background(
            BlurViewUI(style: .systemUltraThinMaterialLight)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.55), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.16), radius: 24, x: 0, y: 18)
        .foregroundColor(.white)
    }
}

private struct GlassMetricView: View {
    let value: String
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.white.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
