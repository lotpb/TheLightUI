//
//  ReelsView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import AVKit
import SwiftUI

@available(iOS 15.0, *)
struct ReelsView: View {
    fileprivate enum Layout {
        static let pagePadding: CGFloat = 16
        static let bottomPadding: CGFloat = 20
        static let avatarSize: CGFloat = 35
        static let albumArtSize: CGFloat = 30
        static let muteTapSize: CGFloat = 150
        static let expandedCaptionHeight: CGFloat = 120
    }

    @StateObject private var viewModel = MainMessagesViewModel()
    @State private var currentReel = ""
    @State private var reels = ReelsView.loadReels()

    var body: some View {
        GeometryReader { proxy in
            if reels.isEmpty {
                ReelsEmptyState()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            } else {
                reelsPager(size: proxy.size)
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .background(Color.black.ignoresSafeArea())
        .onAppear(perform: selectInitialReel)
        .task { await viewModel.fetchCurrentUser() }
    }

    private func reelsPager(size: CGSize) -> some View {
        TabView(selection: $currentReel) {
            ForEach(reels) { reel in
                ReelsPlayer(
                    reel: reel,
                    currentReel: currentReel,
                    profileImageUrl: viewModel.chatUser?.profileImageUrl
                )
                .frame(width: size.width)
                .padding(Layout.pagePadding)
                .rotationEffect(.degrees(-90))
                .ignoresSafeArea(.all, edges: .top)
                .tag(reel.id)
            }
        }
        .rotationEffect(.degrees(90))
        .frame(width: size.height)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(width: size.width)
    }

    private func selectInitialReel() {
        guard currentReel.isEmpty else { return }
        currentReel = reels.first?.id ?? ""
    }

    private static func loadReels() -> [Reel] {
        MediaFile.sampleFiles.compactMap { item in
            guard let url = Bundle.main.url(forResource: item.url, withExtension: "mp4") else {
                return nil
            }

            let player = AVPlayer(url: url)
            player.actionAtItemEnd = .none
            return Reel(player: player, mediaFile: item)
        }
    }
}

@available(iOS 15.0, *)
private struct ReelsPlayer: View {
    let reel: Reel
    let currentReel: String
    let profileImageUrl: String?

    @State private var showMore = false
    @State private var isMuted = false
    @State private var volumeAnimation = false
    @State private var isFollowing = false
    @State private var volumeFeedbackTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            CustomVideoPlayer(player: reel.player)
                .onAppear {
                    updatePlayback(reel.player)
                }
                .onChange(of: currentReel) {
                    updatePlayback(reel.player)
                }
//                .onChange(of: currentReel) { _ in
//                    updatePlayback(reel.player)
//                }
                .onDisappear {
                    reel.player.pause()
                    volumeFeedbackTask?.cancel()
                }

            muteTapTarget(player: reel.player)
            expandedCaptionDismissLayer
            reelOverlay
            volumeIndicator
        }
    }

    private var reelOverlay: some View {
        VStack {
            HStack(alignment: .bottom) {
                ReelCaptionView(
                    reel: reel,
                    profileImageUrl: profileImageUrl,
                    showMore: $showMore,
                    isFollowing: $isFollowing
                )

                Spacer(minLength: 20)

                ActionButtons(reel: reel)
            }

            ReelAudioRow()
                .padding(.top, 10)
        }
        .padding(.horizontal)
        .padding(.bottom, 20)
        .foregroundColor(.white)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var expandedCaptionDismissLayer: some View {
        Color.black.opacity(showMore ? 0.35 : 0)
            .onTapGesture {
                withAnimation {
                    showMore.toggle()
                }
            }
    }

    private var volumeIndicator: some View {
        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            .font(.title)
            .foregroundColor(.white)
            .padding()
            .background(.secondary)
            .clipShape(Circle())
            .opacity(volumeAnimation ? 1 : 0)
    }

    private func muteTapTarget(player: AVPlayer) -> some View {
        Color.black.opacity(0.01)
            .frame(width: ReelsView.Layout.muteTapSize, height: ReelsView.Layout.muteTapSize)
            .onTapGesture {
                toggleMute(player)
            }
    }

    private func updatePlayback(_ player: AVPlayer) {
        if currentReel == reel.id {
            player.play()
        } else {
            player.pause()
        }
    }

    private func toggleMute(_ player: AVPlayer) {
        guard !volumeAnimation else { return }

        isMuted.toggle()
        player.isMuted = isMuted

        withAnimation {
            volumeAnimation = true
        }

        volumeFeedbackTask?.cancel()
        volumeFeedbackTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }

            withAnimation {
                volumeAnimation = false
            }
        }
    }
}

@available(iOS 15.0, *)
private struct ReelCaptionView: View {
    let reel: Reel
    let profileImageUrl: String?
    @Binding var showMore: Bool
    @Binding var isFollowing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            authorRow
            caption
        }
    }

    private var authorRow: some View {
        HStack(spacing: 15) {
            ProfileAvatarImage(urlString: profileImageUrl, fallbackImageName: "IMG_3408")
                .frame(width: ReelsView.Layout.avatarSize, height: ReelsView.Layout.avatarSize)
                .clipShape(Circle())

            Text("Peter")
                .font(.callout.bold())

            Button {
                isFollowing.toggle()
            } label: {
                Text(isFollowing ? "Following" : "Follow")
                    .font(.caption.bold())
            }
            .buttonStyle(.borderless)
        }
    }

    @ViewBuilder
    private var caption: some View {
        if showMore {
            ScrollView(.vertical, showsIndicators: false) {
                Text(reel.mediaFile.title + Self.expandedCaptionText)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: ReelsView.Layout.expandedCaptionHeight)
            .onTapGesture(perform: toggleCaption)
        } else {
            Button(action: toggleCaption) {
                HStack {
                    Text(reel.mediaFile.title)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text("more")
                        .font(.callout.bold())
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func toggleCaption() {
        withAnimation {
            showMore.toggle()
        }
    }

    private static let expandedCaptionText = " hktftfluyglgihilighi oyggigpi gggpip pggih."
}

@available(iOS 15.0, *)
private struct ReelAudioRow: View {
    var body: some View {
        HStack {
            Text("A Sky full of Stars")
                .font(.caption)
                .fontWeight(.semibold)

            Spacer(minLength: 20)

            Image("taylor_swift_profile")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: ReelsView.Layout.albumArtSize, height: ReelsView.Layout.albumArtSize)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .background {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color.white, lineWidth: 3)
                }
                .offset(x: -5)
        }
    }
}

@available(iOS 15.0, *)
private struct ActionButtons: View {
    let reel: Reel
    @State private var isLiked = false

    var body: some View {
        VStack(spacing: 25) {
            Button {
                withAnimation(.spring()) {
                    isLiked.toggle()
                }
            } label: {
                ReelActionLabel(
                    systemImage: isLiked ? "suit.heart.fill" : "suit.heart",
                    text: isLiked ? "234K" : "233K"
                )
            }
            .accessibilityLabel(isLiked ? "Unlike reel" : "Like reel")

            Button { } label: {
                ReelActionLabel(systemImage: "bubble.right", text: "120")
            }
            .accessibilityLabel("Comments for \(reel.mediaFile.title)")

            Button { } label: {
                ReelActionLabel(systemImage: "paperplane")
            }
            .accessibilityLabel("Share reel")

            Button { } label: {
                Image(systemName: "ellipsis")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            }
            .accessibilityLabel("More options")
        }
    }
}

@available(iOS 15.0, *)
private struct ReelActionLabel: View {
    let systemImage: String
    let text: String?

    init(systemImage: String, text: String? = nil) {
        self.systemImage = systemImage
        self.text = text
    }

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title)

            if let text {
                Text(text)
                    .font(.caption.bold())
            }
        }
    }
}

@available(iOS 15.0, *)
private struct ReelsEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "play.slash")
                .font(.largeTitle)
                .foregroundColor(.white.opacity(0.7))

            Text("No reels available")
                .font(.headline)
                .foregroundColor(.white)

            Text("Add MP4 files to the app bundle to show reels here.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}

@available(iOS 15.0, *)
#Preview("Reels") {
    ReelsView()
        .preferredColorScheme(.dark)
}
