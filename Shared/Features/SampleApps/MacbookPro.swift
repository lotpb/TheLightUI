//
//  MacbookPro.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 7/4/21.
//

import SwiftUI

struct MacbookPro: View {
    // The artwork is drawn on a fixed canvas: a 1265x695 screen with the
    // base/hinge extending below and wider than it (~1430pt after its 1.7x
    // scale). These bounds (plus a small margin) are used to scale the
    // whole drawing down to fit the available space.
    private let designSize = CGSize(width: 1480, height: 850)

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / designSize.width,
                proxy.size.height / designSize.height,
                1
            )

            artwork
                .offset(y: -49) // recenter: the base now hangs below the screen frame
                .scaleEffect(scale)
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private var artwork: some View {
        ZStack {
            MacBookScreen()
                .frame(width: 1265, height: 695) //1265-695

            MacBookBase()
                .frame(width: 1200, height: 1000) //1200-1000
        }
    }
}

#Preview("MacbookPro") {
    MacbookPro()
        .preferredColorScheme(.light)
}

private struct MacBookScreen: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(Color("Gray"), lineWidth: 6)

            VStack(spacing: 0) {
                Image("macOS")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 1200, height: 590)
                    .clipped()
                    .padding(.top, 40)
                    .padding(.bottom, 15)

                Rectangle()
                    .fill(Color.white.opacity(0.14))
                    .overlay(
                        Text("MacBook Pro")
                            .foregroundStyle(.white)
                            .offset(y: -13)
                    )
            }

            M5ProChipBadge()
                .offset(y: -25) // center of the wallpaper area, above the name band

            CameraIndicator()
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: 17)
        }
    }
}

private struct M5ProChipBadge: View {
    private let chipGradient = LinearGradient(
        colors: [Color.blue, Color.purple, Color.pink, Color.orange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(Color.black)

            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .strokeBorder(chipGradient, lineWidth: 5)

            HStack(spacing: 20) {
                Image(systemName: "applelogo")
                    .font(.system(size: 90))

                VStack(spacing: 0) {
                    Text("M5")
                        .font(.system(size: 84, weight: .semibold))

                    Text("Pro")
                        .font(.system(size: 46, weight: .medium))
                }
            }
            .foregroundStyle(.white)
        }
        .frame(width: 380, height: 260)
        .shadow(color: Color.purple.opacity(0.5), radius: 40)
    }
}

private struct CameraIndicator: View {
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 10, height: 10)

                Circle()
                    .fill(Color.black)
                    .frame(width: 3, height: 3)
            }

            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
        }
    }
}

private struct MacBookBase: View {
    private let hingeGradient = [
        Color("Gray2"),
        Color("Gray1").opacity(0.7),
        Color("Gray2"),
        Color("Gray2"),
        Color("Gray2"),
        Color("Gray2")
    ]

    var body: some View {
        ZStack {
            hinge

            lowerBody
                .scaleEffect(0.672)
                .rotation3DEffect(.degrees(-70), axis: (x: 1, y: 0, z: 0), anchor: .center, anchorZ: 1, perspective: 3)
                .offset(y: 15.5)
        }
        .scaleEffect(1.7)
        .overlay(trackpad.offset(y: -13))
        .offset(y: 347) // hinge straddles the bottom edge of the 695pt-tall screen
 //120
    }

    private var hinge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.gray)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(colors: hingeGradient, startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 180)
                .frame(maxWidth: .infinity, alignment: .leading)

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(
                    LinearGradient(colors: hingeGradient.reversed(), startPoint: .leading, endPoint: .trailing)
                )
                .frame(width: 180)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 25)
        .scaleEffect(0.7)
    }

    private var lowerBody: some View {
        CustomCorners(corners: [.bottomLeft, .bottomRight], radius: 20)
            .fill(Color("Gray1").opacity(0.5))
            .frame(height: 50)
            .overlay(baseMaterialGradient)
            .overlay(baseDepthGradient)
    }

    private var baseMaterialGradient: some View {
        CustomCorners(corners: [.bottomLeft, .bottomRight], radius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        Color("Gray1").opacity(0.4),
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }

    private var baseDepthGradient: some View {
        CustomCorners(corners: [.bottomLeft, .bottomRight], radius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(height: 80)
            .rotation3DEffect(.degrees(50), axis: (x: 1, y: 0, z: 0), anchor: .center, anchorZ: 0, perspective: 3)
            .shadow(radius: 2)
            .offset(y: 50)
    }

    private var trackpad: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 100, style: .continuous)
                .fill(Color.gray.opacity(0.4))

            RoundedRectangle(cornerRadius: 100, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: trackpadGradient,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            RoundedRectangle(cornerRadius: 100, style: .continuous)
                .fill(Color.black.opacity(0.1))
        }
        .frame(width: 220, height: 35)
        .clipped()
    }

    private var trackpadGradient: [Color] {
        let clearColors = Array(repeating: Color.clear, count: 12)
        let colors: [Color] = [
            Color.black.opacity(0.55),
            Color.black.opacity(0.25),
            Color.black.opacity(0.05)
        ]

        return colors + clearColors + colors.reversed()
    }
}
