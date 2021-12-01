//
//  MediaFile.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 7/2/21.
//

import SwiftUI

struct MediaFile: Identifiable {
    var id = UUID().uuidString
    var url: String
    var title: String
    var isExpanded: Bool = false
    
}

var MediaFileJSON = [
    
    MediaFile(url: "Reel1", title: "Apple AirTag....."),
    MediaFile(url: "Reel2", title: "Beautful Sky....."),
    MediaFile(url: "Reel3", title: "Paradiso....."),
    MediaFile(url: "Reel4", title: "Apple AirTag....."),
    MediaFile(url: "Reel5", title: "Apple AirTag....."),
    MediaFile(url: "Reel6", title: "Apple AirTag....."),
    
]
