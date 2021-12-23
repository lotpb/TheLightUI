//
//  ChatMessage.swift
//  TheLightUI
//
//  Created by Peter Balsamo on 12/9/21.
//

import Foundation
import FirebaseFirestoreSwift


struct ChatMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let fromId, toId, text: String
    let timestamp: Date
    
}
