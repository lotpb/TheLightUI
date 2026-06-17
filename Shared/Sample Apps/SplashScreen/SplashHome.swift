//
//  SplashHome.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/26/21.
//

import SwiftUI

struct SplashHome: View {
    @State private var currentTab = SplashTab.allPhotos.rawValue
    @Namespace private var animation
    
    private let photoIndexes = Array(1...6)
    
    var body: some View {
        ZStack {
            SplashHomeBackground()

            VStack(alignment: .leading, spacing: 18) {
                tabBar
                header
                photoGrid
            }
            .padding(.top, 18)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(SplashTab.allCases) { tab in
                TabButtonSplash(title: tab.rawValue, animation: animation, currentTab: $currentTab)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color(.separator).opacity(0.12), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(currentTab)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Text("Recent moments from your visual library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 18)
    }

    private var photoGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(photoIndexes, id: \.self) { index in
                    SplashPhotoCard(index: index)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

private enum SplashTab: String, CaseIterable, Identifiable {
    case allPhotos = "All photos"
    case chats = "Chats"
    case status = "Status"
    
    var id: String { rawValue }
}

private struct SplashHomeBackground: View {
    var body: some View {
        LinearGradient(
            colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

private struct SplashPhotoCard: View {
    let index: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("taylor_swift_profile")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            LinearGradient(
                colors: [.clear, .black.opacity(0.62)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("Moment \(index)")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("TheLight photo collection")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
            }
            .padding(18)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

#Preview("Splash Home - Dark") {
    SplashHome()
        .preferredColorScheme(.dark)
}

struct TabButtonSplash: View {
    let title: String
    let animation: Namespace.ID
    @Binding var currentTab: String
    
    private var isSelected: Bool { currentTab == title }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                currentTab = title
            }
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(Color.purple)
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
