//
//  CarouselSliderUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/15/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct CarouselSliderUI: View {

    var body: some View {
        CarouselSliderHomeView()
    }
}

#Preview("Carousel Slider") {
    CarouselSliderUI()
}

private enum CarouselStyle {
    static let maxContentWidth: CGFloat = 430
    static let horizontalPadding: CGFloat = 24
    static let slideCornerRadius: CGFloat = 32
    static let buttonHeight: CGFloat = 54
    static let imageMaxHeight: CGFloat = 270

    static let ink = Color(red: 0.08, green: 0.10, blue: 0.16)
    static let secondaryInk = Color(red: 0.36, green: 0.40, blue: 0.48)
    static let accent = Color(red: 0.05, green: 0.52, blue: 0.74)
    static let coral = Color(red: 0.95, green: 0.48, blue: 0.50)
}

private struct CarouselSlide: Identifiable {
    let id: Int
    let imageName: String
    let title: String
    let subtitle: String
}

private struct SignupAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let style: SignupButton.Style
}

private struct CarouselSliderHomeView: View {
    @State private var currentIndex = 1

    private let slides = [
        CarouselSlide(
            id: 1,
            imageName: "profile-rabbit-toy",
            title: "TheLight",
            subtitle: "Company to expand to a new web advertising directive this week."
        ),
        CarouselSlide(
            id: 2,
            imageName: "profile-rabbit-toy",
            title: "Create faster",
            subtitle: "Build polished screens with focused SwiftUI components."
        ),
        CarouselSlide(
            id: 3,
            imageName: "profile-rabbit-toy",
            title: "Share anywhere",
            subtitle: "Start with a clean account and keep your projects in sync."
        )
    ]

    private let actions = [
        SignupAction(title: "Sign up with Apple", systemImage: "applelogo", style: .primary),
        SignupAction(title: "Sign up with Google", systemImage: "globe", style: .secondary(iconColor: .red)),
        SignupAction(title: "Sign up with Email", systemImage: "envelope.fill", style: .secondary(iconColor: CarouselStyle.accent))
    ]

    var body: some View {
        ZStack {
            CarouselBackground()

            VStack(spacing: 20) {
                TabView(selection: $currentIndex) {
                    ForEach(slides) { slide in
                        CarouselSlideView(slide: slide)
                            .tag(slide.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                CustomTabIndicator(count: slides.count, current: currentIndex)

                signupActions
            }
            .padding(.horizontal, CarouselStyle.horizontalPadding)
            .padding(.vertical, 28)
            .frame(maxWidth: CarouselStyle.maxContentWidth)
        }
    }

    private var signupActions: some View {
        VStack(spacing: 12) {
            ForEach(actions) { action in
                SignupButton(action: action)
            }

            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundStyle(CarouselStyle.secondaryInk)

                Button("Log in") {}
                    .fontWeight(.semibold)
                    .foregroundStyle(CarouselStyle.ink)
            }
            .font(.footnote)
            .padding(.top, 10)
        }
    }
}

private struct CarouselBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.93, green: 0.98, blue: 0.99),
                    Color(red: 0.80, green: 0.91, blue: 0.95),
                    Color(red: 0.99, green: 0.88, blue: 0.84)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                Color.white.opacity(0.58)
                    .frame(height: 220)
                    .blur(radius: 34)

                Spacer()

                CarouselStyle.coral.opacity(0.16)
                    .frame(height: 240)
                    .blur(radius: 44)
            }
        }
        .ignoresSafeArea()
    }
}

private struct CarouselSlideView: View {
    let slide: CarouselSlide

    var body: some View {
        GeometryReader { proxy in
            let minX = proxy.frame(in: .global).minX
            let width = max(proxy.size.width, 1)
            let progress = abs(minX / width)
            let scale = max(0.9, 1 - (progress * 0.08))

            VStack(spacing: 22) {
                Spacer(minLength: 0)

                Image(slide.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: CarouselStyle.imageMaxHeight)
                    .padding(.horizontal, 18)

                VStack(spacing: 10) {
                    Text(slide.title)
                        .font(.system(size: 36, weight: .heavy, design: .rounded))
                        .foregroundStyle(CarouselStyle.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Text(slide.subtitle)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CarouselStyle.secondaryInk)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
            .padding(24)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CarouselStyle.slideCornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: CarouselStyle.slideCornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.10), radius: 26, x: 0, y: 18)
            .scaleEffect(scale)
            .animation(.easeOut(duration: 0.2), value: scale)
        }
    }
}

private struct SignupButton: View {
    enum Style {
        case primary
        case secondary(iconColor: Color)

        var foregroundColor: Color {
            switch self {
            case .primary: .white
            case .secondary: CarouselStyle.ink
            }
        }

        var backgroundColor: Color {
            switch self {
            case .primary: CarouselStyle.ink
            case .secondary: .white.opacity(0.70)
            }
        }

        var borderColor: Color {
            switch self {
            case .primary: .clear
            case .secondary: .white.opacity(0.86)
            }
        }

        var iconColor: Color {
            switch self {
            case .primary: .white
            case .secondary(let iconColor): iconColor
            }
        }
    }

    let action: SignupAction

    var body: some View {
        Button {} label: {
            Label {
                Text(action.title)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .center)
            } icon: {
                Image(systemName: action.systemImage)
                    .font(.system(size: 19, weight: .semibold))
                    .frame(width: 24)
                    .foregroundStyle(action.style.iconColor)
            }
            .foregroundStyle(action.style.foregroundColor)
            .padding(.horizontal, 18)
            .frame(height: CarouselStyle.buttonHeight)
            .background(action.style.backgroundColor, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(action.style.borderColor, lineWidth: 1)
            }
            .shadow(color: .black.opacity(action.style.shadowOpacity), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

private extension SignupButton.Style {
    var shadowOpacity: Double {
        switch self {
        case .primary: 0.14
        case .secondary: 0.06
        }
    }
}

private struct CustomTabIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(1...count, id: \.self) { index in
                Capsule()
                    .fill(current == index ? CarouselStyle.ink : CarouselStyle.ink.opacity(0.18))
                    .frame(width: current == index ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.28, dampingFraction: 0.8), value: current)
            }
        }
        .padding(.vertical, 2)
    }
}
