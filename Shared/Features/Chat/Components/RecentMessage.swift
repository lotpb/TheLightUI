//
//  RecentMessage.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/9/21.
//

import Foundation
import FirebaseFirestore

struct RecentMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let text: String
    let email: String
    let fromId: String
    let toId: String
    let profileImageUrl: String
    let timestamp: Date
    
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }

    func daysAndHoursAgoText(relativeTo date: Date) -> String {
        Duration.seconds(max(0, date.timeIntervalSince(timestamp)))
            .formatted(.units(allowed: [.days, .hours, .minutes, .seconds], width: .narrow, maximumUnitCount: 1))
    }
}
