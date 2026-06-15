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
            self.modelContainer(for: Expense.self)
        } else {
            self
        }
    }
}
