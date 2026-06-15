//
//  InstagramUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/17/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct InstagramUI: View {
    @State private var selectedTab = "square.grid.3x3"
    @State private var topHeaderOffset: CGFloat = 0
    @Namespace private var animation
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .background(headerOffsetReader)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    Divider()
                    profileSummary
                    profileBio
                    profileActions
                    storyHighlights
                    stickyTabBar
                    postGrid
                }
            }
        }
    }

    private var headerView: some View {
        HStack(spacing: 15) {
            Button {
            } label: {
                Text("_Kavsoft")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "plus.app")
                    .font(.title)
                    .foregroundColor(.primary)
            }

            Button {
            } label: {
                Image(systemName: "line.horizontal.3")
                    .font(.title)
                    .foregroundColor(.primary)
            }
        }
        .padding([.horizontal, .top])
        .padding(.bottom, 8)
    }

    private var headerOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    if topHeaderOffset == 0 {
                        topHeaderOffset = proxy.frame(in: .global).minY
                    }
                }
                .onChange(of: proxy.frame(in: .global).minY) { minY in
                    if topHeaderOffset == 0 {
                        topHeaderOffset = minY
                    }
                }
        }
    }

    private var profileSummary: some View {
        HStack {
            Button {
            } label: {
                Image("taylor_swift_profile")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .padding(2)
                            .background(Color.white)
                            .clipShape(Circle())
                            .offset(x: 5, y: 5)
                    }
            }

            ProfileStatView(value: "199", title: "Posts")
            ProfileStatView(value: "1,129", title: "Followers")
            ProfileStatView(value: "13", title: "Following")
        }
        .padding()
    }

    private var profileBio: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Kavsoft . iOS & SwiftUI Dev")
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text("Video Creator")
                .fontWeight(.bold)
                .foregroundColor(.secondary)

            Text("ftfkftdky kutfufkufkuulf lyuflul ulglggglggl glglgi7glglig iggliglggllgli ggukggykgkgkugku")

            Link("Link", destination: URL(string: "https://www.apple.com")!)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    private var profileActions: some View {
        HStack(spacing: 10) {
            ProfileActionButton(title: "Edit Profile")
            ProfileActionButton(title: "Promotions")
        }
        .padding([.horizontal, .top])
    }

    private var storyHighlights: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                Button {
                } label: {
                    VStack {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(18)
                            .background(Circle().stroke(Color.secondary))

                        Text("New")
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding([.horizontal, .top])
        }
    }

    private var stickyTabBar: some View {
        GeometryReader { proxy in
            let minY = proxy.frame(in: .global).minY
            let offset = minY - topHeaderOffset

            HStack(spacing: 0) {
                TabBarButtonUI(image: "square.grid.3x3", isSystemImage: true, animation: animation, selectedTab: $selectedTab)
                TabBarButtonUI(image: "film", isSystemImage: false, animation: animation, selectedTab: $selectedTab)
                TabBarButtonUI(image: "person.crop.square", isSystemImage: true, animation: animation, selectedTab: $selectedTab)
            }
            .frame(height: 50, alignment: .bottom)
            .background(scheme == .dark ? Color.black : Color.white)
            .offset(y: offset < 0 ? -offset : 0)
        }
        .frame(height: 50)
        .zIndex(4)
    }

    private var postGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
            ForEach(1...30, id: \.self) { index in
                GeometryReader { proxy in
                    let width = proxy.size.width
                    ImageView(index: index, width: width)
                }
                .frame(height: 120)
            }
        }
    }
}

struct InstagramUI_Previews: PreviewProvider {
    static var previews: some View {
        InstagramUI()
    }
}

private struct ProfileStatView: View {
    let value: String
    let title: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(title)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ProfileActionButton: View {
    let title: String

    var body: some View {
        Button {
        } label: {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary)
                )
        }
    }
}

struct ImageView: View {
    var index: Int
    var width: CGFloat

    var body: some View {
        let imageName = index > 10 ? index - (10 * (index / 10)) == 0 ? 10 : index - (10 * (index / 10)) : index

        Image("post\(imageName)")
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: 120)
            .clipped()
    }
}

struct TabBarButtonUI: View {
    var image: String
    var isSystemImage: Bool
    var animation: Namespace.ID
    @Binding var selectedTab: String

    var body: some View {
        Button {
            withAnimation(.easeOut) {
                selectedTab = image
            }
        } label: {
            VStack(spacing: 12) {
                (isSystemImage ? Image(systemName: image) : Image(image))
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 28, height: 28)
                    .foregroundColor(selectedTab == image ? .primary : .secondary)

                ZStack {
                    if selectedTab == image {
                        Rectangle()
                            .fill(Color.primary)
                            .matchedGeometryEffect(id: "TAB", in: animation)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                    }
                }
                .frame(height: 1)
            }
        }
    }
}
