//
//  MediaFile.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import Foundation

struct MediaFile: Identifiable {
    let id: String
    let url: String
    let title: String

    init(id: String = UUID().uuidString, url: String, title: String) {
        self.id = id
        self.url = url
        self.title = title
    }
}

extension MediaFile {
    static let sampleFiles = [
        MediaFile(url: "Reel1", title: "Apple AirTag....."),
        MediaFile(url: "Reel2", title: "Beautiful Sky....."),
        MediaFile(url: "Reel3", title: "Paradiso....."),
        MediaFile(url: "Reel4", title: "Apple AirTag....."),
        MediaFile(url: "Reel5", title: "Apple AirTag....."),
        MediaFile(url: "Reel6", title: "Apple AirTag.....")
    ]
}
