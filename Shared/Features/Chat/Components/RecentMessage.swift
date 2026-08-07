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
    let firstName: String?
    let lastName: String?

    var username: String {
        let parts = [firstName, lastName].compactMap { s -> String? in
            guard let s, !s.isEmpty else { return nil }
            return s
        }
        return parts.isEmpty ? (email.components(separatedBy: "@").first ?? email) : parts.joined(separator: " ")
    }

    func daysAndHoursAgoText(relativeTo date: Date) -> String {
        Duration.seconds(max(0, date.timeIntervalSince(timestamp)))
            .formatted(.units(allowed: [.days, .hours, .minutes, .seconds], width: .narrow, maximumUnitCount: 1))
    }
}
