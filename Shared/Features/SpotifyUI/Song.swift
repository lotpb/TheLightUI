//
//  Song.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/10/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import Foundation

struct Song: Identifiable, Hashable, Sendable {
    let id = UUID()
    let albumName: String
    let albumAuthor: String
    let albumCover: String
}

// Static sample content backing the Spotify demo screen.
enum MusicLibrary {
    static let recentlyPlayed: [Song] = [
        Song(albumName: "Bad Blood", albumAuthor: "Taylor Swift", albumCover: "taylor_swift_profile"),
        Song(albumName: "Believer", albumAuthor: "Kurt Hugo Schneider", albumCover: "taylor_swift_profile"),
        Song(albumName: "Let Me Love You", albumAuthor: "DJ Snake", albumCover: "taylor_swift_profile"),
        Song(albumName: "Shape Of You", albumAuthor: "Ed Sheeran", albumCover: "taylor_swift_profile"),
    ]

    static let likedSongs: [Song] = [
        Song(albumName: "Bad Blood", albumAuthor: "Taylor Swift", albumCover: "taylor_swift_profile"),
        Song(albumName: "Believer", albumAuthor: "Kurt Hugo Schneider", albumCover: "taylor_swift_profile"),
        Song(albumName: "Let Me Love You", albumAuthor: "DJ Snake", albumCover: "taylor_swift_profile"),
        Song(albumName: "Shape Of You", albumAuthor: "Ed Sheeran", albumCover: "taylor_swift_profile"),
    ]

    static let genres = ["Classic", "Hip-Hop", "Electronic", "Chillout", "Dark", "Calm", "Ambient", "Dance"]
}
