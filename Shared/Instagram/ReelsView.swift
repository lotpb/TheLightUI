//
//  ReelsView.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI
import AVKit

@available(iOS 15.0, *)
struct ReelsView: View {
    @StateObject private var viewModel = MainMessagesViewModel()
    @State private var currentReel = ""
    @State private var reels = ReelsView.loadReels()

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            if reels.isEmpty {
                ReelsEmptyState()
                    .frame(width: size.width, height: size.height)
            } else {
                TabView(selection: $currentReel) {
                    ForEach($reels) { $reel in
                        ReelsPlayer(
                            reel: $reel,
                            currentReel: $currentReel,
                            profileImageUrl: viewModel.chatUser?.profileImageUrl
                        )
                            .frame(width: size.width)
                            .padding()
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
        }
        .ignoresSafeArea(.all, edges: .top)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            guard currentReel.isEmpty else { return }
            currentReel = reels.first?.id ?? ""
        }
        .task { await viewModel.fetchCurrentUser() }
    }

    private static func loadReels() -> [Reel] {
        MediaFileJSON.compactMap { item in
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
    @Binding var reel: Reel
    @Binding var currentReel: String
    let profileImageUrl: String?

    @State private var showMore = false
    @State private var isMuted = false
    @State private var volumeAnimation = false
    @State private var isFollowing = false

    var body: some View {
        ZStack {
            if let player = reel.player {
                CustomVideoPlayer(player: player)
                    .onAppear {
                        updatePlayback(player)
                    }
                    .onChange(of: currentReel) { _ in
                        updatePlayback(player)
                    }
                    .onDisappear {
                        player.pause()
                    }

                Color.black.opacity(0.01)
                    .frame(width: 150, height: 150)
                    .onTapGesture {
                        toggleMute(player)
                    }

                Color.black.opacity(showMore ? 0.35 : 0)
                    .onTapGesture {
                        withAnimation {
                            showMore.toggle()
                        }
                    }

                VStack {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 15) {
                                ProfileAvatarImage(urlString: profileImageUrl, fallbackImageName: "IMG_3408")
                                    .frame(width: 35, height: 35)
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

                            ZStack {
                                if showMore {
                                    ScrollView(.vertical, showsIndicators: false) {
                                        Text(reel.mediaFile.title + sampleText)
                                            .font(.callout)
                                            .fontWeight(.semibold)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .frame(height: 120)
                                    .onTapGesture {
                                        withAnimation {
                                            showMore.toggle()
                                        }
                                    }
                                } else {
                                    Button {
                                        withAnimation {
                                            showMore.toggle()
                                        }
                                    } label: {
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
                        }

                        Spacer(minLength: 20)

                        ActionButtons(reel: reel)
                    }

                    HStack {
                        Text("A Sky full of Stars")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Spacer(minLength: 20)

                        Image("taylor_swift_profile")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 30, height: 30)
                            .cornerRadius(6)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 3)
                            )
                            .offset(x: -5)
                    }
                    .padding(.top, 10)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                .foregroundColor(.white)
                .frame(maxHeight: .infinity, alignment: .bottom)

                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(.secondary)
                    .clipShape(Circle())
                    .opacity(volumeAnimation ? 1 : 0)
            }
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                volumeAnimation = false
            }
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
                VStack(spacing: 10) {
                    Image(systemName: isLiked ? "suit.heart.fill" : "suit.heart")
                        .font(.title)

                    Text(isLiked ? "234K" : "233K")
                        .font(.caption.bold())
                }
            }
            .accessibilityLabel(isLiked ? "Unlike reel" : "Like reel")

            Button {
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "bubble.right")
                        .font(.title)

                    Text("120")
                        .font(.caption.bold())
                }
            }
            .accessibilityLabel("Comments for \(reel.mediaFile.title)")

            Button {
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "paperplane")
                        .font(.title)
                }
            }
            .accessibilityLabel("Share reel")

            Button {
            } label: {
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

private let sampleText = " hktftfluyglgihilighi oyggigpi gggpip pggih."
