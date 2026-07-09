//
//  ExpenseModelContainerModifier.swift
//  TheLightUI
//

import SwiftUI
import SwiftData

extension View {
    @ViewBuilder
    func expenseModelContainer() -> some View {
        // Keep this gate at the SwiftData floor (iOS 17): "Designed for iPad" on
        // the Mac reports the macOS-equivalent iOS version (e.g. 26.x), so a
        // higher gate silently drops the container there and Expenses shows empty.
        if #available(iOS 17.0, *) {
            ExpenseModelContainerView(content: self)
        } else {
            self
        }
    }
}

@available(iOS 17.0, *)
private struct ExpenseModelContainerView<Content: View>: View {
    let content: Content

    var body: some View {
        if let container = ExpenseModelContainerFactory.shared {
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

@available(iOS 17.0, *)
@MainActor
private enum ExpenseModelContainerFactory {
    /// One container shared by every entry point (Expense tab and the main-menu
    /// route). Each entry point previously built its own container over the same
    /// store, so an import saved through one screen never reached the @Query of
    /// the other, still-alive screen.
    static let shared: ModelContainer? = makeContainer()

    private static func makeContainer() -> ModelContainer? {
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
