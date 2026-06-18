//
//  Reel.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import AVKit

struct Reel: Identifiable {
    let id: String
    let player: AVPlayer
    let mediaFile: MediaFile

    init(id: String = UUID().uuidString, player: AVPlayer, mediaFile: MediaFile) {
        self.id = id
        self.player = player
        self.mediaFile = mediaFile
    }
}
