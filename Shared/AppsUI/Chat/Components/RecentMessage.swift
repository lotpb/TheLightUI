//
//  RecentMessage.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/9/21.
//

import Foundation
import FirebaseFirestoreSwift

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
}

