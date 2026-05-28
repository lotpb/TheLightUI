//
//  ListView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI


struct ListView: View {
    
    @StateObject private var listViewModel: ListViewModel
    @State private var isCompleted = false

    init(listViewModel: ListViewModel = ListViewModel(itemStore: UserDefaultsItemStore())) {
        _listViewModel = StateObject(wrappedValue: listViewModel)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            let visibleItems = isCompleted ? listViewModel.items.filter { $0.isCompleted } : listViewModel.items

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
                        NavigationLink {
                            AddView().environmentObject(listViewModel)
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
                    Picker("Filter", selection: $isCompleted) {
                        Text("All").tag(false)
                        Text("Completed").tag(true)
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
                            Toggle(isOn: $isCompleted) {
                                Text("Show Completed")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
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
