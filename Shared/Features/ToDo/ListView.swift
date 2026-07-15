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
                        .refreshable { listViewModel.getItems() }
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
