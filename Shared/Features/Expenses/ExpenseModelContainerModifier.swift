//
//  ExpenseModelContainerModifier.swift
//  TheLightUI
//

import SwiftUI
import SwiftData

extension View {
    @ViewBuilder
    func expenseModelContainer() -> some View {
        if #available(iOS 27.0, *) {
            ExpenseModelContainerView(content: self)
        } else {
            self
        }
    }
}

@available(iOS 27.0, *)
private struct ExpenseModelContainerView<Content: View>: View {
    let content: Content
    @State private var container = ExpenseModelContainerFactory.makeContainer()

    var body: some View {
        if let container {
            content.modelContainer(container)
        } else {
            ContentUnavailableView(
                "Expenses Unavailable",
                systemImage: "exclamationmark.triangle",
                description: Text("The expense store could not be opened.")
            )
        }
    }
}

@available(iOS 27.0, *)
private enum ExpenseModelContainerFactory {
    @MainActor
    static func makeContainer() -> ModelContainer? {
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
            assertionFailure("Failed to load fallback in-memory Expense SwiftData store: \(error)")
            return nil
        }
    }
}
