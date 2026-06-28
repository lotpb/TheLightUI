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
                .padding(.horizontal, GlassStyle.screenPadding)
        }
        .ignoresSafeArea()
    }
}

private enum GlassStyle {
    static let screenPadding: CGFloat = 24
    static let cornerRadius: CGFloat = 30
    static let cardMaxWidth: CGFloat = 360
    static let iconSize: CGFloat = 52
    static let tint = Color(red: 0.10, green: 0.58, blue: 0.78)
    static let accent = Color(red: 0.96, green: 0.45, blue: 0.52)
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.20)
    static let secondaryInk = Color(red: 0.28, green: 0.33, blue: 0.42)

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

private struct GlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.97, blue: 0.98),
                    Color(red: 0.77, green: 0.88, blue: 0.92),
                    Color(red: 0.98, green: 0.86, blue: 0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [.white.opacity(0.72), .clear, GlassStyle.tint.opacity(0.18)],
                startPoint: .top,
                endPoint: .bottom
            )
            .blendMode(.softLight)

            VStack(spacing: 0) {
                BackgroundGlow(color: .white.opacity(0.55), height: 220, blur: 34)
                Spacer()
                BackgroundGlow(color: GlassStyle.accent.opacity(0.20), height: 240, blur: 42)
            }
        }
    }
}

private struct BackgroundGlow: View {
    let color: Color
    let height: CGFloat
    let blur: CGFloat

    var body: some View {
        color
            .frame(height: height)
            .blur(radius: blur)
    }
}

private struct GlassCard: View {
    private let metrics = [
        GlassMetric(value: "24", title: "Screens"),
        GlassMetric(value: "8", title: "Styles"),
        GlassMetric(value: "3", title: "Themes")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            cardHeader
            cardDescription
            metricsRow
            actionButton
        }
        .padding(24)
        .frame(maxWidth: GlassStyle.cardMaxWidth)
        .background(.ultraThinMaterial, in: GlassStyle.cardShape)
        .overlay {
            GlassStyle.cardShape
                .stroke(.white.opacity(0.74), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 28, x: 0, y: 18)
        .shadow(color: GlassStyle.tint.opacity(0.16), radius: 44, x: 0, y: 20)
    }

    private var cardHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.42))

                Image(systemName: "sparkles")
                    .font(.system(size: 24, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(GlassStyle.tint)
            }
            .frame(width: GlassStyle.iconSize, height: GlassStyle.iconSize)

            VStack(alignment: .leading, spacing: 4) {
                Text("TheLight Software")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(GlassStyle.ink)

                Text("Glass interface study")
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                    .foregroundStyle(GlassStyle.secondaryInk.opacity(0.72))
            }
        }
    }

    private var cardDescription: some View {
        Text("Soft translucent layers with crisp controls, tuned spacing, and calm iOS-style contrast.")
            .font(.subheadline)
            .lineSpacing(3)
            .foregroundStyle(GlassStyle.secondaryInk)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var metricsRow: some View {
        HStack(spacing: 10) {
            ForEach(metrics) { metric in
                GlassMetricView(metric: metric)
            }
        }
    }

    private var actionButton: some View {
        Button {} label: {
            Label("Preview", systemImage: "rectangle.stack.fill")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .foregroundStyle(.white)
                .background(GlassStyle.ink, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct GlassMetric: Identifiable {
    let value: String
    let title: String

    var id: String { title }
}

private struct GlassMetricView: View {
    let metric: GlassMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(metric.value)
                .font(.headline.weight(.bold))
                .foregroundStyle(GlassStyle.ink)

            Text(metric.title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(GlassStyle.secondaryInk.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white.opacity(0.34), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(.white.opacity(0.52), lineWidth: 1)
        }
    }
}

@available(iOS 18.0, *)
#Preview("Glass Morphism") {
    GlassMorphism()
}
