//
//  Gradient.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/8/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

// MARK: - GradientUI
@MainActor
struct GradientUI: View {
    fileprivate enum Layout {
        static let titleSize: CGFloat = 60
        static let titlePadding: CGFloat = 28
        static let stackSpacing: CGFloat = 18
        static let subtitleTracking: CGFloat = 1.5
    }

    var body: some View {
        ZStack {
            GradientBackground()

            VStack(spacing: Layout.stackSpacing) {
                TitleText("TheLight")
                SubtitleText("Software")
                VersionText(AppSettingsStore().version)
            }
            .padding(.horizontal, Layout.titlePadding)
            .multilineTextAlignment(.center)
            // Accessibility: combine for a concise announcement
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Reusable Text Components
private struct TitleText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: GradientUI.Layout.titleSize, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.45)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct SubtitleText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(.white.opacity(0.78))
            .textCase(.uppercase)
            .tracking(GradientUI.Layout.subtitleTracking)
    }
}

private struct VersionText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text("Version \(text)")
            .font(.footnote)
            .fontWeight(.medium)
            .foregroundStyle(.white.opacity(0.55))
    }
}

// MARK: - Background
private struct GradientBackground: View {
    private enum Colors {
        static let radialStart = Color(red: 0.42, green: 0.16, blue: 0.95)
        static let radialEnd = Color(red: 0.04, green: 0.02, blue: 0.16)
    }

    private enum Metrics {
        static let radialStartRadius: CGFloat = 5
        static let radialEndRadius: CGFloat = 550
    }

    var body: some View {
        RadialGradient(
            colors: [Colors.radialStart, Colors.radialEnd],
            center: .center,
            startRadius: Metrics.radialStartRadius,
            endRadius: Metrics.radialEndRadius
        )
        .ignoresSafeArea()
    }
}

// MARK: - Preview
@available(iOS 18.0, *)
#Preview("Gradient UI", traits: .portrait) {
    GradientUI()
}

