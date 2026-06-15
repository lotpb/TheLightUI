//
//  BottomSheetUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/24/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct BottomActionSheetUI: View {
    @State private var searchText = ""
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @GestureState private var gestureOffset: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let height = proxy.size.height
            let maxHeight = max(height - 100, 0)

            ZStack {
                backgroundImage(maxHeight: maxHeight)
                bottomSheet(height: height, maxHeight: maxHeight)
            }
            .ignoresSafeArea()
        }
    }

    private func backgroundImage(maxHeight: CGFloat) -> some View {
        Image("profile-rabbit-toy")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .clipped()
            .blur(radius: blurRadius(maxHeight: maxHeight))
    }

    private func bottomSheet(height: CGFloat, maxHeight: CGFloat) -> some View {
        ZStack {
            BlurViewUI(style: .systemThinMaterialDark)
                .clipShape(CustomCorners(corners: [.topLeft, .topRight], radius: 18))

            VStack(spacing: 0) {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 60, height: 4)
                    .padding(.top)

                SearchField(text: $searchText)
                    .padding(.top, 10)

                BottomSheetContent()
            }
            .padding(.horizontal)
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .offset(y: sheetOffset(height: height, maxHeight: maxHeight))
        .gesture(sheetDragGesture(maxHeight: maxHeight))
        .ignoresSafeArea(.all, edges: .bottom)
    }

    private func sheetOffset(height: CGFloat, maxHeight: CGFloat) -> CGFloat {
        let proposedOffset = offset + gestureOffset
        let clampedOffset = min(max(proposedOffset, -maxHeight), 0)
        return height - 100 + clampedOffset
    }

    private func sheetDragGesture(maxHeight: CGFloat) -> some Gesture {
        DragGesture()
            .updating($gestureOffset) { value, state, _ in
                state = value.translation.height
            }
            .onEnded { value in
                let proposedOffset = lastOffset + value.translation.height
                let clampedOffset = min(max(proposedOffset, -maxHeight), 0)
                let expandedThreshold = -maxHeight / 2
                let partialThreshold: CGFloat = -100

                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    if clampedOffset < expandedThreshold {
                        offset = -maxHeight
                    } else if clampedOffset < partialThreshold {
                        offset = -(maxHeight / 3)
                    } else {
                        offset = 0
                    }

                    lastOffset = offset
                }
            }
    }

    private func blurRadius(maxHeight: CGFloat) -> CGFloat {
        guard maxHeight > 0 else { return 0 }
        let progress = min(max(-offset / maxHeight, 0), 1)
        return progress * 30
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        TextField("Search", text: $text)
            .padding(.vertical, 10)
            .padding(.horizontal)
            .background(BlurViewUI(style: .dark))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .colorScheme(.dark)
            .foregroundColor(.white)
    }
}

private struct BottomSheetContent: View {
    private let favorites = [
        FavoriteAction(title: "Home", systemImage: "house.fill"),
        FavoriteAction(title: "Work", systemImage: "briefcase.fill"),
        FavoriteAction(title: "Add", systemImage: "plus")
    ]

    var body: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Favorites")
                .padding(.top, 20)

            Divider()
                .background(Color.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(favorites) { favorite in
                        FavoriteActionButton(favorite: favorite)
                    }
                }
            }
            .padding(.top)

            SectionHeader(title: "Editor's Pick")
                .padding(.top, 25)

            Divider()
                .background(Color.white)
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Button {
            } label: {
                Text("See All")
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct FavoriteAction: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
}

private struct FavoriteActionButton: View {
    let favorite: FavoriteAction

    var body: some View {
        VStack(spacing: 8) {
            Button {
            } label: {
                Image(systemName: favorite.systemImage)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 65, height: 65)
                    .background(BlurViewUI(style: .dark))
                    .clipShape(Circle())
            }

            Text(favorite.title)
                .foregroundColor(.white)
        }
    }
}

struct BottomActionSheetUI_Previews: PreviewProvider {
    static var previews: some View {
        BottomActionSheetUI()
    }
}

