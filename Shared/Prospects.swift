//
//  Prospects.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/26/22.
//

import SwiftUI

class Prospect: Identifiable, Codable, Comparable {
    
    var id = UUID()
    var name = "Anonymous"
    var email = ""
    var dateAdded = Date.now
    fileprivate(set) var isContacted = false
    
    var displayedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM y"
        return formatter.string(from: dateAdded)
    }
    
    static func <(lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.name < rhs.name
    }
    
    static func == (lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.id == rhs.id
    }
}

class Prospects: ObservableObject {
    
    @Published private(set) var people: [Prospect]
    let savedPath = FileManager.documentDirectory.appendingPathComponent("savedProspects")
    
    init() {
        do {
            let data = try Data(contentsOf: savedPath)
            people = try JSONDecoder().decode([Prospect].self, from: data)
        } catch {
            people = []
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(people)
            try data.write(to: savedPath, options: [.atomic, .completeFileProtection])
        } catch {
            print("Unexpected error")
        }
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
    
    func toggle(_ prospect: Prospect) {
        objectWillChange.send()
        prospect.isContacted.toggle()
        save()
    }
}


extension FileManager {
    
    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
