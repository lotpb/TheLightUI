//
//  DataBackupSection.swift
//  TheLightUI
//

// Settings section that controls where the Expense tracker and To Do list
// store their data: on this device as JSON, or in Firebase. Manual backup,
// restore, and JSON transfer live in each feature's own menu.

import SwiftUI
import SwiftData

struct DataBackupSection: View {
    private enum BackendOption: String, CaseIterable, Identifiable {
        case firebase = "Firebase"
        case parse = "Parse"

        var id: Self { self }
    }

    /// Bound to AppSettingsStore.isFirebaseData: when on, the Expense
    /// tracker and To Do list load from and save to Firebase automatically.
    @Binding var isFirebaseData: Bool

    /// Bound to AppSettingsStore.backend (the legacy Firebase/Parse choice).
    @Binding var backend: String

    @State private var isSyncing = false
    @State private var resultMessage: String?
    @State private var isShowingResult = false

    var body: some View {
        Section {
            Picker("Cloud Storage", selection: $backend) {
                ForEach(BackendOption.allCases) { option in
                    Text(option.rawValue)
                        .tag(option.rawValue)
                }
            }
            // Inverted presentation of isFirebaseData: on = keep data on
            // this device, off = store in Firebase.
            Toggle(isOn: Binding(
                get: { !isFirebaseData },
                set: { isFirebaseData = !$0 }
            )) {
                Label("Store Data on Device", systemImage: "iphone")
            }
            .disabled(isSyncing)
            .onChange(of: isFirebaseData) { _, enabled in
                if enabled {
                    seedFirebase()
                }
            }
            .alert(resultMessage ?? "", isPresented: $isShowingResult) {
                Button("OK", role: .cancel) {}
            }
            if isSyncing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Syncing with Firebase…")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Data Storage")
        } footer: {
            Text("When on, expenses and to-do items stay on this device. Turn it off to load from and save to Firebase automatically.")
        }
    }

    /// Pushes the current local data up when Firebase storage is switched
    /// on, so the remote collections start from this device's state.
    private func seedFirebase() {
        run(failureLabel: "Sync failed") {
            var pushed: [String] = []
            if #available(iOS 17.0, *), let context = ExpenseModelContainerFactory.shared?.mainContext {
                let expenses = (try? context.fetch(FetchDescriptor<Expense>())) ?? []
                if !expenses.isEmpty {
                    try await ExpenseFirestoreService().backUp(expenses.map(ExpenseRecord.init))
                    pushed.append("\(expenses.count) expense\(expenses.count == 1 ? "" : "s")")
                }
            }
            let items = UserDefaultsItemStore().loadItems() ?? []
            if !items.isEmpty {
                try await ToDoFirestoreService().backUp(items)
                pushed.append("\(items.count) to-do item\(items.count == 1 ? "" : "s")")
            }
            guard !pushed.isEmpty else {
                return "Firebase storage is on. New data will save to Firebase."
            }
            return "Firebase storage is on. Backed up \(pushed.joined(separator: " and "))."
        }
    }

    /// Runs the operation with the syncing indicator up, then reports the
    /// returned message (or the error) through the result alert.
    private func run(failureLabel: String, _ operation: @escaping () async throws -> String) {
        isSyncing = true
        Task {
            defer { isSyncing = false }
            do {
                showResult(try await operation())
            } catch {
                showResult("\(failureLabel): \(error.localizedDescription)")
            }
        }
    }

    private func showResult(_ message: String) {
        resultMessage = message
        isShowingResult = true
    }
}

#Preview("Data Storage") {
    @Previewable @State var isFirebaseData = false
    @Previewable @State var backend = "Firebase"
    Form {
        DataBackupSection(isFirebaseData: $isFirebaseData, backend: $backend)
    }
}
