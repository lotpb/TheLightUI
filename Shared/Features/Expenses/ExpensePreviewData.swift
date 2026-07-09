//
//  ExpensePreviewData.swift
//  TheLightUI
//

import Foundation
import SwiftData

/// Sample expenses and an in-memory container for SwiftUI previews.
enum ExpensePreviewData {
    @MainActor
    static var container: ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Expense.self, configurations: configuration)

        sampleExpenses.forEach { container.mainContext.insert($0) }
        return container
    }

    static var sampleExpenses: [Expense] {
        [
            Expense(title: "Client lunch", amount: 84.32, category: .meals, date: .now.addingTimeInterval(-86400), notes: "Downtown meeting", isReimbursable: true),
            Expense(title: "Design software", amount: 29.99, category: .software, date: .now.addingTimeInterval(-172800), isReimbursable: false),
            Expense(title: "Airport parking", amount: 46.00, category: .travel, date: .now.addingTimeInterval(-259200), isReimbursable: true),
            Expense(title: "Office supplies", amount: 118.47, category: .supplies, date: .now.addingTimeInterval(-432000), isReimbursable: false)
        ]
    }
}
