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

            glassContent
        }
        .ignoresSafeArea()
    }

    /// Hosts the glass shapes in a `GlassEffectContainer` on iOS 26+ so the card
    /// and toolbar render together and can blend or morph; earlier systems
    /// present the same stack directly.
    @ViewBuilder
    private var glassContent: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                stackedContent
            }
        } else {
            stackedContent
        }
    }

    private var stackedContent: some View {
        VStack(spacing: 28) {
            GlassCard()
                .padding(.horizontal, GlassStyle.screenPadding)

            GlassToolbar()
        }
    }
}

// Floating toolbar of circular glass controls. On iOS 26 each circle uses the
// interactive Liquid Glass variant, so it reacts to touch like a glass button.
private struct GlassToolbar: View {
    private let actions: [(symbol: String, title: String)] = [
        ("paintbrush.fill", "Paint"),
        ("wand.and.stars", "Effects"),
        ("square.on.square", "Layers")
    ]

    var body: some View {
        HStack(spacing: 20) {
            ForEach(actions, id: \.symbol) { action in
                Button {} label: {
                    Image(systemName: action.symbol)
                        .font(.system(size: 19, weight: .semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(GlassStyle.ink)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.plain)
                .glassSurface(in: Circle(), interactive: true)
                .accessibilityLabel(action.title)
            }
        }
    }
}

private enum GlassStyle {
    static let screenPadding: CGFloat = 24
    static let cornerRadius: CGFloat = 30
    static let cardMaxWidth: CGFloat = 360
    static let iconSize: CGFloat = 52
    static let tint = Color(red: 0.42, green: 0.36, blue: 0.90)
    static let accent = Color(red: 0.98, green: 0.66, blue: 0.36)
    static let ink = Color(red: 0.13, green: 0.11, blue: 0.28)
    static let secondaryInk = Color(red: 0.35, green: 0.33, blue: 0.50)

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

private struct GlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.93, blue: 0.99),
                    Color(red: 0.79, green: 0.80, blue: 0.95),
                    Color(red: 0.99, green: 0.88, blue: 0.79)
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
        .glassSurface(in: GlassStyle.cardShape)
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

    @ViewBuilder
    private var actionButton: some View {
        if #available(iOS 26.0, *) {
            // Prominent Liquid Glass CTA: the style supplies its own glass
            // capsule and legible foreground; tint carries the brand color.
            Button {} label: { actionLabel }
                .buttonStyle(.glassProminent)
                .tint(GlassStyle.ink)
        } else {
            Button {} label: {
                actionLabel
                    .foregroundStyle(.white)
                    .background(GlassStyle.ink, in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var actionLabel: some View {
        Label("Preview", systemImage: "rectangle.stack.fill")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
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

// MARK: - Liquid Glass surface

/// Applies a true Liquid Glass material on iOS 26+, falling back to the
/// translucent material + hairline-stroke treatment on earlier systems so
/// the card keeps its frosted look on older devices.
private struct GlassSurface<S: Shape>: ViewModifier {
    let shape: S
    let fallbackStrokeOpacity: Double
    var interactive = false

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            // Liquid Glass supplies its own edge highlight, so the manual
            // stroke used in the fallback is intentionally dropped here.
            content.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(.white.opacity(fallbackStrokeOpacity), lineWidth: 1)
                }
        }
    }
}

private extension View {
    func glassSurface<S: Shape>(
        in shape: S,
        fallbackStrokeOpacity: Double = 0.74,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassSurface(shape: shape, fallbackStrokeOpacity: fallbackStrokeOpacity, interactive: interactive))
    }
}

#Preview("Glass Morphism") {
    GlassMorphism()
}
