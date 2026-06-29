//
//  ListView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI

struct ListView: View {

    @State private var listViewModel: ListViewModel
    @State private var showingAddSheet = false

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

            if listViewModel.visibleItems.isEmpty {
                NoItemsView { showingAddSheet = true }
                    .transition(.opacity)
            } else {
                VStack(spacing: 12) {
                    ToDoHeaderView(count: listViewModel.visibleItems.count) {
                        showingAddSheet = true
                    }

                    Picker("Filter", selection: $listViewModel.filter) {
                        ForEach(ToDoFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

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
                    .refreshable { listViewModel.getItems() }
                }
            }
        }
        .navigationTitle("To Do List ✍️")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { } label: { Label("Share List", systemImage: "square.and.arrow.up") }
                    Button { } label: { Label("Sort By", systemImage: "arrow.up.arrow.down") }
                    Button { } label: { Label("Print", systemImage: "printer") }
                    Button(role: .destructive) { } label: { Label("Delete List", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                AddView()
            }
            .environment(listViewModel)
        }
    }
}

/// Header card showing the visible item count with a quick-add action.
private struct ToDoHeaderView: View {
    let count: Int
    var onAdd: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("To Do's")
                    .font(.title2.weight(.semibold))
                Text("^[\(count) item](inflect: true)")
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
