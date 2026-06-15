//
//  Song.swift
//  TheLight2
//
//  Created by Peter Balsamo on 5/10/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct Song: Identifiable {
    
    var id = UUID().uuidString
    var album_name : String
    var album_author : String
    var album_cover : String
}

var recentlyPlayed = [
    
    Song(album_name: "Bad Blood", album_author: "Taylor Swift", album_cover: "taylor_swift_profile"),
    Song(album_name: "Believer", album_author: "Kurt Hugo Schneider", album_cover: "taylor_swift_profile"),
    Song(album_name: "Let Me Love You", album_author: "DJ Snake", album_cover: "taylor_swift_profile"),
    Song(album_name: "Shape Of You", album_author: "Ed Sherran", album_cover: "taylor_swift_profile"),
]

var likedSongs = [
    
    Song(album_name: "Bad Blood", album_author: "Taylor Swift", album_cover: "taylor_swift_profile"),
    Song(album_name: "Believer", album_author: "Kurt Hugo Schneider", album_cover: "taylor_swift_profile"),
    Song(album_name: "Let Me Love You", album_author: "DJ Snake", album_cover: "taylor_swift_profile"),
    Song(album_name: "Shape Of You", album_author: "Ed Sherran", album_cover: "taylor_swift_profile"),
]

var generes = ["Classic", "Hip-Hop", "Electronic", "Chilout", "Dark", "Calm", "Ambient", "Dance"]
