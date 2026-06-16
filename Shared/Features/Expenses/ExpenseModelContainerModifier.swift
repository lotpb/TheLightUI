//
//  ExpenseModelContainerModifier.swift
//  TheLightUI
//

import SwiftUI
import SwiftData

extension View {
    @ViewBuilder
    func expenseModelContainer() -> some View {
        if #available(iOS 17.0, *) {
            self.modelContainer(ExpenseModelContainerFactory.shared)
        } else {
            self
        }
    }
}

@available(iOS 17.0, *)
private enum ExpenseModelContainerFactory {
    @MainActor
    static let shared: ModelContainer = makeContainer()

    @MainActor
    private static func makeContainer() -> ModelContainer {
        let schema = Schema([Expense.self])
        let persistentConfiguration = ModelConfiguration(schema: schema)

        do {
            return try ModelContainer(for: schema, configurations: [persistentConfiguration])
        } catch {
            assertionFailure("Failed to load persistent Expense SwiftData store: \(error)")
        }

        do {
            let memoryConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try ModelContainer(for: schema, configurations: [memoryConfiguration])
        } catch {
            preconditionFailure("Failed to load fallback in-memory Expense SwiftData store: \(error)")
        }
    }
}
