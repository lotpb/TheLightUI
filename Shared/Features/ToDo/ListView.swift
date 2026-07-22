//
//  ListView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI

struct ListView: View {

    @Environment(\.tabBarOverlap) private var tabBarOverlap

    @State private var listViewModel: ListViewModel
    @State private var showingAddSheet = false
    @State private var showingClearConfirmation = false

    // JSON import/export state (file pickers and result alert).
    @State private var transferViewModel = ToDoTransferViewModel()
    @State private var isSyncing = false

    @MainActor
    init(listViewModel: ListViewModel? = nil) {
        // Construct the default model in the init body: a main-actor-isolated
        // initializer can't be called from a nonisolated default argument.
        _listViewModel = State(initialValue: listViewModel ?? ListViewModel(itemStore: UserDefaultsItemStore()))
    }

    var body: some View {
        @Bindable var listViewModel = listViewModel

        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if listViewModel.visibleItems.isEmpty && listViewModel.items.isEmpty {
                NoItemsView { showingAddSheet = true }
                    .transition(.opacity)
            } else {
                VStack(spacing: 12) {
                    ToDoHeaderView(
                        total: listViewModel.items.count,
                        completed: listViewModel.completedCount
                    ) {
                        showingAddSheet = true
                    }

                    Picker("Filter", selection: $listViewModel.filter) {
                        ForEach(ToDoFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if listViewModel.visibleItems.isEmpty {
                        ContentUnavailableView(
                            "Nothing Here",
                            systemImage: "line.3.horizontal.decrease.circle",
                            description: Text("No items match the \"\(listViewModel.filter.title)\" filter.")
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            Section {
                                ForEach(listViewModel.visibleItems) { item in
                                    ListRowView(item: item)
                                        .contentShape(.rect)
                                        .onTapGesture {
                                            withAnimation(.snappy) {
                                                listViewModel.updateItem(item: item)
                                            }
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                            Button(role: .destructive) {
                                                withAnimation(.easeInOut) {
                                                    listViewModel.deleteItem(item)
                                                }
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                                .onDelete(perform: listViewModel.deleteItem)
                                .onMove(perform: listViewModel.moveItem)
                            } header: {
                                Text(listViewModel.filter.title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listStyle(.insetGrouped)
                        // Space the rows apart so each renders as its own
                        // rounded card, like Reminders.
                        .listRowSpacing(10)
                        .refreshable {
                            listViewModel.getItems()
                            await listViewModel.refreshFromFirebase()
                        }
                    }
                }
            }
        }
        // The custom tab bar's safe-area inset is applied outside this
        // screen's NavigationStack, which doesn't forward it to the List's
        // scroll insets — re-apply it so the last row rests above the bar.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear
                .frame(height: tabBarOverlap)
                .allowsHitTesting(false)
        }
        // No nav title — the header card already titles the screen; inline
        // mode keeps the bar compact instead of reserving large-title space.
        .navigationBarTitleDisplayMode(.inline)
        // No-op unless "Store Data in Firebase" is on in Settings.
        .task { await listViewModel.refreshFromFirebase() }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                    ShareLink(item: listViewModel.shareText) {
                        Label("Share List", systemImage: "square.and.arrow.up")
                    }
                    .disabled(listViewModel.items.isEmpty)
                    Button {
                        withAnimation(.snappy) { listViewModel.sortItems() }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                    .disabled(listViewModel.items.isEmpty)
                    Divider()
                    // Import stays enabled with an empty list so a backup can
                    // restore it; export needs items to write.
                    Button {
                        transferViewModel.isImporting = true
                    } label: {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                    }
                    Button {
                        transferViewModel.startExport(items: listViewModel.items)
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                    }
                    .disabled(listViewModel.items.isEmpty)
                    Divider()
                    Button {
                        backUpToFirebase()
                    } label: {
                        Label("Back Up to Firebase", systemImage: "icloud.and.arrow.up")
                    }
                    .disabled(listViewModel.items.isEmpty || isSyncing)
                    Button {
                        restoreFromFirebase()
                    } label: {
                        Label("Restore from Firebase", systemImage: "icloud.and.arrow.down")
                    }
                    .disabled(isSyncing)
                    Button {
                        printList()
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                    .disabled(listViewModel.items.isEmpty)
                    Divider()
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Label("Delete List", systemImage: "trash")
                    }
                    .disabled(listViewModel.items.isEmpty)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .confirmationDialog(
            "Delete all items?",
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                withAnimation(.easeInOut) { listViewModel.clearAll() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This permanently removes every item from your list.")
        }
        // .data is included because fileExporter on some iOS versions saves the
        // file without a .json extension, which the system then types as generic
        // data and the picker would grey out.
        .fileImporter(isPresented: $transferViewModel.isImporting, allowedContentTypes: [.json, .plainText, .data]) { result in
            transferViewModel.handleImport(result) { items in
                listViewModel.importItems(items)
            }
        }
        .fileExporter(
            isPresented: $transferViewModel.isExporting,
            document: transferViewModel.exportDocument,
            contentType: .json,
            defaultFilename: "ToDoListBackup.json"
        ) { result in
            transferViewModel.finishExport(result)
        }
        .alert(transferViewModel.alertMessage ?? "", isPresented: $transferViewModel.isShowingAlert) {
            Button("OK", role: .cancel) {}
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                AddView()
            }
            .environment(listViewModel)
        }
    }

    private var printableHTML: String {
        let items = listViewModel.items
        let completed = items.filter { $0.isCompleted }.count
        var rows = ""
        for item in items {
            let status = item.isCompleted ? "&#10003;" : ""
            let title = item.title
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            let rowClass = item.isCompleted ? " class=\"done\"" : ""
            rows += "<tr\(rowClass)><td class=\"check\">\(status)</td><td>\(title)</td></tr>\n"
        }
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          body { font-family: -apple-system, Helvetica Neue, Arial, sans-serif; margin: 40px; color: #1c1c1e; }
          .header { border-bottom: 2px solid #007aff; padding-bottom: 14px; margin-bottom: 24px; }
          .title { font-size: 26px; font-weight: 700; color: #007aff; }
          .subtitle { font-size: 14px; color: #6e6e73; margin-top: 4px; }
          table { width: 100%; border-collapse: collapse; margin-bottom: 24px; }
          tr:nth-child(even) { background-color: #f2f2f7; }
          td { padding: 8px 12px; font-size: 14px; vertical-align: top; }
          .check { width: 32px; text-align: center; color: #34c759; font-weight: 700; }
          .done td { color: #aeaeb2; text-decoration: line-through; }
          .footer { margin-top: 32px; font-size: 11px; color: #aeaeb2; text-align: right; }
        </style>
        </head>
        <body>
          <div class="header">
            <div class="title">To-Do List</div>
            <div class="subtitle">\(items.count) item\(items.count == 1 ? "" : "s") &bull; \(completed) completed</div>
          </div>
          <table>\(rows)</table>
          <div class="footer">Printed from The Light &bull; \(Date().formatted(date: .long, time: .omitted))</div>
        </body>
        </html>
        """
    }

    private func printList() {
        #if canImport(UIKit)
        let printInfo = UIPrintInfo.printInfo()
        printInfo.outputType = .general
        printInfo.jobName = "To-Do List"
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        let formatter = UIMarkupTextPrintFormatter(markupText: printableHTML)
        controller.printFormatter = formatter
        controller.present(animated: true)
        #endif
    }

    private func backUpToFirebase() {
        // The service is created here rather than stored on the view so
        // previews, which never configure Firebase, don't touch Firestore.
        let items = listViewModel.items
        isSyncing = true
        Task {
            defer { isSyncing = false }
            do {
                try await ToDoFirestoreService().backUp(items)
                transferViewModel.showSyncMessage("Backed up \(items.count) item\(items.count == 1 ? "" : "s") to Firebase.")
            } catch {
                transferViewModel.showSyncMessage("Backup failed: \(error.localizedDescription)")
            }
        }
    }

    private func restoreFromFirebase() {
        isSyncing = true
        Task {
            defer { isSyncing = false }
            do {
                let items = try await ToDoFirestoreService().fetchAll()
                guard !items.isEmpty else {
                    transferViewModel.showSyncMessage("No to-do items found in Firebase.")
                    return
                }
                let counts = listViewModel.importItems(items)
                transferViewModel.showMergeResult(inserted: counts.inserted, updated: counts.updated)
            } catch {
                transferViewModel.showSyncMessage("Restore failed: \(error.localizedDescription)")
            }
        }
    }
}

/// Header card showing overall progress with a quick-add action.
private struct ToDoHeaderView: View {
    let total: Int
    let completed: Int
    var onAdd: () -> Void

    private var progress: Double {
        total == 0 ? 0 : Double(completed) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("To Do's")
                        .font(.title2.weight(.semibold))
                    Text("^[\(total) item](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: onAdd) {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }

            VStack(alignment: .leading, spacing: 6) {
                ProgressView(value: progress)
                    .tint(.green)
                Text("\(completed) of \(total) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.15))
        )
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        ListView()
    }
}
