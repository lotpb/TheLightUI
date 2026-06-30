//
//  SpotifyUI.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/10/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct SpotifyUI: View {
    
    @State private var viewModel = MainMessagesViewModel()
    @State private var searchText = ""
    @State private var showSideBar = false
    
    private var filteredRecentlyPlayed: [Song] {
        filterSongs(recentlyPlayed)
    }
    
    private var filteredLikedSongs: [Song] {
        filterSongs(likedSongs)
    }
    
    private var filteredGenres: [String] {
        guard !searchText.isEmpty else { return generes }
        return generes.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            SpotifyBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    topBar
                    heroHeader
                    recentlyPlayedSection
                    genresSection
                    likedSongsSection
                }
                .padding(.leading, showSideBar ? 102 : 62)
                .padding(.trailing, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
            }
            .scrollIndicators(.hidden)

            SideTabViewUI(showSideBar: $showSideBar, viewModel: viewModel)
        }
        .animation(.snappy(duration: 0.35), value: showSideBar)
        .task { await viewModel.fetchCurrentUser() }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if !showSideBar {
                Button {
                    showSideBar = true
                } label: {
                    Image(systemName: "sidebar.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.10), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.10), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open sidebar")
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.68))

                TextField("Search music", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(.white.opacity(0.10), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.10), lineWidth: 1))

            Button {} label: {
                ProfileAvatarImage(urlString: viewModel.chatUser?.profileImageUrl)
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Good Evening")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(SpotifyStyle.accent)

            Text("Pick up where you left off")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text("Recently played tracks, liked songs, and calm discovery in one place.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var recentlyPlayedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Recently Played", subtitle: "Fresh from your queue")

            if filteredRecentlyPlayed.isEmpty {
                SpotifyEmptyState()
                    .frame(height: 190)
            } else {
                TabView {
                    ForEach(filteredRecentlyPlayed) { item in
                        FeaturedSongCard(song: item)
                            .padding(.horizontal, 2)
                    }
                }
                .frame(height: 360)
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
        }
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Genres", subtitle: "Browse by mood")

            if filteredGenres.isEmpty {
                SpotifyEmptyState()
                    .frame(height: 130)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                    ForEach(filteredGenres, id: \.self) { genre in
                        GenreChip(title: genre)
                    }
                }
            }
        }
    }

    private var likedSongsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Liked Songs", subtitle: "Saved to your library")

            if filteredLikedSongs.isEmpty {
                SpotifyEmptyState()
                    .frame(height: 150)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(filteredLikedSongs) { song in
                        LikedSongRow(song: song)
                    }
                }
            }
        }
        .padding(.bottom, 24)
    }
    
    private func filterSongs(_ songs: [Song]) -> [Song] {
        guard !searchText.isEmpty else { return songs }
        return songs.filter {
            $0.album_name.localizedCaseInsensitiveContains(searchText) ||
            $0.album_author.localizedCaseInsensitiveContains(searchText)
        }
    }
}

enum SpotifyStyle {
    static let background = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let surface = Color.white.opacity(0.10)
    static let accent = Color(red: 0.28, green: 0.90, blue: 0.46)
    static let warmAccent = Color(red: 0.82, green: 0.28, blue: 0.38)
}

private struct SpotifyBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.13, blue: 0.18),
                    SpotifyStyle.background,
                    Color(red: 0.02, green: 0.03, blue: 0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                SpotifyStyle.accent.opacity(0.16)
                    .frame(height: 220)
                    .blur(radius: 54)

                Spacer()

                SpotifyStyle.warmAccent.opacity(0.12)
                    .frame(height: 260)
                    .blur(radius: 60)
            }
        }
        .ignoresSafeArea()
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.56))
            }

            Spacer()

            Button("See All") {}
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.68))
        }
    }
}

private struct FeaturedSongCard: View {
    let song: Song

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(song.album_cover)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            LinearGradient(
                colors: [.clear, .black.opacity(0.18), .black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

            HStack(spacing: 14) {
                Button {} label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 58, height: 58)
                        .background(SpotifyStyle.accent, in: Circle())
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    Text(song.album_name)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(song.album_author)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                }
            }
            .padding(20)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.30), radius: 26, x: 0, y: 18)
    }
}

private struct GenreChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(.white.opacity(0.10), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))
    }
}

private struct LikedSongRow: View {
    let song: Song

    var body: some View {
        HStack(spacing: 12) {
            Image(song.album_cover)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(song.album_name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(song.album_author)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "heart.fill")
                .foregroundStyle(SpotifyStyle.accent)
        }
        .padding(12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct SpotifyEmptyState: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(SpotifyStyle.accent)
            Text("No Results")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Try another search.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
        }
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview("Spotify - Dark") {
    SpotifyUI()
        .preferredColorScheme(.dark)
}
