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

struct CarouselSliderUI_Previews: PreviewProvider {
    static var previews: some View {
        CarouselSliderUI()
    }
}

private struct CarouselSlide: Identifiable {
    let id: Int
    let imageName: String
    let title: String
    let subtitle: String
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

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentIndex) {
                ForEach(slides) { slide in
                    CarouselSlideView(slide: slide)
                        .tag(slide.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            CustomTabIndicator(count: slides.count, current: $currentIndex)
                .padding(.vertical, 24)

            signupActions
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemTeal).ignoresSafeArea())
    }

    private var signupActions: some View {
        VStack(spacing: 15) {
            SignupButton(
                title: "Sign up with Apple",
                systemImage: "applelogo",
                iconColor: .white,
                textColor: .white,
                backgroundColor: .black,
                borderColor: .white
            )

            SignupButton(
                title: "Sign up with Google",
                systemImage: "globe",
                iconColor: .red,
                textColor: .black,
                backgroundColor: .white,
                borderColor: .black
            )

            SignupButton(
                title: "Sign up with Email",
                systemImage: "envelope",
                iconColor: .black,
                textColor: .black,
                backgroundColor: .white,
                borderColor: .black
            )

            HStack(spacing: 4) {
                Text("Already have an account?")
                    .foregroundColor(.white)

                Button {
                } label: {
                    Text("Log in")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .underline(true, color: .white)
                }
            }
            .padding(.top, 24)
        }
    }
}

private struct CarouselSlideView: View {
    let slide: CarouselSlide

    var body: some View {
        GeometryReader { proxy in
            let minX = proxy.frame(in: .global).minX
            let width = max(proxy.size.width, 1)
            let progress = -minX / (width * 2)
            let scale = max(0.7, progress > 0 ? 1 - progress : 1 + progress)

            VStack(spacing: 0) {
                Image(slide.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.horizontal, 70)

                Text(slide.title)
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundColor(.white)
                    .padding(.top, 20)

                Text(slide.subtitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 10)
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            .scaleEffect(scale)
        }
    }
}

private struct SignupButton: View {
    let title: String
    let systemImage: String
    let iconColor: Color
    let textColor: Color
    let backgroundColor: Color
    let borderColor: Color

    var body: some View {
        Button {
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.vertical, 13)
            .padding(.horizontal)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
    }
}

private struct CustomTabIndicator: View {
    let count: Int
    @Binding var current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill((current - 1) == index ? Color.black : Color.white)
                    .overlay(
                        Circle()
                            .stroke(Color.black, lineWidth: (current - 1) == index ? 0 : 1.5)
                    )
                    .frame(width: 10, height: 10)
            }
        }
    }
}
