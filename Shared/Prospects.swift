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
        Self.displayedDateFormatter.string(from: dateAdded)
    }
    
    private static let displayedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM y"
        return formatter
    }()
    
    static func <(lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.name < rhs.name
    }
    
    static func == (lhs: Prospect, rhs: Prospect) -> Bool {
        lhs.id == rhs.id
    }
}

@MainActor
class Prospects: ObservableObject {
    
    @Published private(set) var people: [Prospect]
    private let savedPath = FileManager.documentDirectory.appendingPathComponent("savedProspects")
    
    init() {
        do {
            let data = try Data(contentsOf: savedPath)
            people = try JSONDecoder().decode([Prospect].self, from: data)
        } catch {
            people = []
            print("Unable to load prospects: \(error.localizedDescription)")
        }
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(people)
            try data.write(to: savedPath, options: [.atomic, .completeFileProtection])
        } catch {
            print("Unable to save prospects: \(error.localizedDescription)")
        }
    }
    
    func add(_ prospect: Prospect) {
        people.append(prospect)
        save()
    }
    
    func toggle(_ prospect: Prospect) {
        guard let index = people.firstIndex(of: prospect) else { return }
        people[index].isContacted.toggle()
        people = Array(people)
        save()
    }
}

extension FileManager {
    
    static var documentDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
