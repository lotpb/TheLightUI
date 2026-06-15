//
//  ListView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI

enum ToDoFilter: String, CaseIterable, Identifiable {
    case all
    case completed
    case notCompleted

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "All"
        case .completed:
            "Completed"
        case .notCompleted:
            "Not Completed"
        }
    }

    func includes(_ item: ItemModel) -> Bool {
        switch self {
        case .all:
            true
        case .completed:
            item.isCompleted
        case .notCompleted:
            !item.isCompleted
        }
    }
}

struct ListView: View {
    
    @StateObject private var listViewModel: ListViewModel
    @State private var selectedFilter: ToDoFilter = .notCompleted
    @State private var showingAddSheet = false

    init(listViewModel: ListViewModel = ListViewModel(itemStore: UserDefaultsItemStore())) {
        _listViewModel = StateObject(wrappedValue: listViewModel)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            let visibleItems = listViewModel.items.filter { selectedFilter.includes($0) }

            if visibleItems.isEmpty {
                NoItemsView()
                    .transition(.opacity)
            } else {
                VStack(spacing: 12) {
                    // Header card with count and quick add
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("To Do's")
                                .font(.title2.weight(.semibold))
                            Text("\(visibleItems.count) items")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Add", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.15))
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Filter control
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(ToDoFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    List {
                        Section {
                            ForEach(visibleItems) { item in
                                ListRowView(item: item)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation(.snappy) {
                                            listViewModel.updateItem(item: item)
                                        }
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            if let index = listViewModel.items.firstIndex(where: { $0.id == item.id }) {
                                                withAnimation(.easeInOut) {
                                                    listViewModel.deleteItem(at: IndexSet(integer: index))
                                                }
                                            }
                                        } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                            .onDelete(perform: listViewModel.deleteItem)
                            .onMove(perform: listViewModel.moveItem)
                        } header: {
                            Text(selectedFilter.title)
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
            ToolbarItem(placement: .navigationBarLeading) { EditButton() }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { } label: { Label("Share List", systemImage: "square.and.arrow.up") }
                    Button { } label: { Label("Sort By", systemImage: "arrow.up.arrow.down") }
                    Button { } label: { Label("Print", systemImage: "printer") }
                    Button(role: .destructive) { } label: { Label("Delete List", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddView()
                .environmentObject(listViewModel)
        }
    }
    
}


struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ListView()
        }
    }
}

