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
    
    private static let relativeDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    var username: String {
        email.components(separatedBy: "@").first ?? email
    }
    
    var timeAgo: String {
        Self.relativeDateFormatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var sentDateText: String {
        MessageDateFormatting.compactDateTime(for: timestamp)
    }

    var daysAndHoursAgoText: String {
        daysAndHoursAgoText(relativeTo: Date())
    }

    func daysAndHoursAgoText(relativeTo date: Date) -> String {
        let elapsedSeconds = max(0, Int(date.timeIntervalSince(timestamp)))
        let days = elapsedSeconds / 86_400
        let hours = elapsedSeconds / 3_600
        let minutes = elapsedSeconds / 60

        if days > 0 {
            return "\(days)d"
        }

        if hours > 0 {
            return "\(hours)h"
        }

        if minutes > 0 {
            return "\(minutes)m"
        }

        return "\(elapsedSeconds)s"
    }
}

