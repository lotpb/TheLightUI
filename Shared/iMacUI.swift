//
//  iMacUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 7/13/21.
//

import SwiftUI

struct iMacUI: View {
    var body: some View {
        iMacScreenView()
    }
}

struct iMacUI_Previews: PreviewProvider {
    static var previews: some View {
        iMacUI()
            .previewLayout(.fixed(width: 1500, height: 1299))
    }
}

private struct iMacScreenView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color.purple)

            Image(systemName: "applelogo")
                .font(.system(size: 180))
                .foregroundColor(.gray)
                .offset(y: -60)

            iMacPortsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .offset(x: 130, y: -40)

            PowerButton()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .offset(x: -50, y: -35)

            iMacStandView()
        }
        .frame(width: 1000, height: 700)
    }
}

private struct iMacPortsView: View {
    private let ports = [false, false, true, true]

    var body: some View {
        HStack(spacing: 20) {
            ForEach(Array(ports.enumerated()), id: \.offset) { _, hasThunderbolt in
                USBTypeCPort(thunderbolt: hasThunderbolt)
            }
        }
    }
}

private struct PowerButton: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.purple)

            Image(systemName: "power")
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.7))
        }
        .frame(width: 33, height: 33)
        .overlay(
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: 3)
                .shadow(color: Color.black.opacity(0.4), radius: 5, x: 5, y: 5)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.4), radius: 5, x: -5, y: -5)
                .clipShape(Circle())
        )
    }
}

private struct USBTypeCPort: View {
    let thunderbolt: Bool

    init(thunderbolt: Bool = false) {
        self.thunderbolt = thunderbolt
    }

    var body: some View {
        VStack(spacing: 5) {
            Image("thunderbolt")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 8, height: 8)
                .foregroundColor(Color.gray.opacity(0.6))
                .opacity(thunderbolt ? 1 : 0)

            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 6, height: 18)

                Capsule()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 2, height: 14)
                    .overlay(USBTypeCPinStack())
            }
        }
    }
}

private struct USBTypeCPinStack: View {
    var body: some View {
        VStack {
            Capsule()
                .fill(Color.purple.opacity(0.7))
                .frame(width: 1, height: 1)

            Spacer()

            Capsule()
                .fill(Color.purple.opacity(0.7))
                .frame(width: 1, height: 1)
        }
    }
}

private struct iMacStandView: View {
    var body: some View {
        ZStack {
            standNeck

            ZStack {
                Capsule()
                    .fill(Color.purple)

                PowerCordView()
            }
            .frame(width: 50, height: 90)
            .offset(y: -35)

            iMacFootView()
                .offset(y: 160)
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .offset(y: 150)
    }

    private var standNeck: some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(Color.gray)
            .frame(width: 220, height: 320)
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.8)] + Array(repeating: Color.gray, count: 4),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 55)
            }
            .overlay(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.gray,
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.7)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 20)
                    .offset(y: 10)
            }
    }
}

private struct iMacFootView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            HStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.gray)
                    .frame(width: 30, height: 3)
                    .offset(y: 2)

                Spacer()

                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.gray)
                    .frame(width: 30, height: 3)
                    .offset(y: 2)
            }
            .padding(.horizontal, 4)

            ZStack {
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.gray)
                    .shadow(color: Color.black.opacity(0.12), radius: 5, x: 0, y: -5)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: footGradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .frame(width: 220, height: 10)
    }

    private var footGradient: [Color] {
        let stand = Array(repeating: Color.gray, count: 20)
        let colors: [Color] = [
            Color.white.opacity(0.1),
            Color.white.opacity(0.2)
        ]

        return colors + stand + colors.reversed()
    }
}

private struct PowerCordView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black, lineWidth: 0.5)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.gray,
                            Color.black.opacity(0.6)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(.bottom, 1)
                .offset(y: 1)

            cordSocket

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.7),
                            Color.gray,
                            Color.black.opacity(0.5)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .frame(width: 24, height: 24)
        }
        .frame(width: 28, height: 28)
        .offset(y: -10)
    }

    private var cordSocket: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                .padding(5)

            Circle()
                .stroke(Color.black.opacity(0.9), lineWidth: 1)
                .padding(4)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black,
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.2)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(6)

            plugDetail
        }
        .frame(width: 20, height: 20)
    }

    private var plugDetail: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.5))

            Rectangle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 1, height: 1.5)
                .offset(x: -3.3, y: 0.5)

            Rectangle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 1, height: 1.5)
                .offset(x: 3.3, y: 0.5)
        }
        .padding(8)
    }
}
