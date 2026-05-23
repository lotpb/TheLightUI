//
//  ListView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI


struct ListView: View {
    
    @StateObject private var listViewModel = ListViewModel()
    @State private var isCompleted = false

    var body: some View {
        
        ZStack {
            if listViewModel.items.isEmpty{
                NoItemsView()
            } else {
                List {
                    Toggle(isOn: $isCompleted) {
                        let countItem = listViewModel.items.count
                        Text("\(countItem) To Do's")
                            .font(.body)
                            .foregroundColor(.gray)

                    }
                    ForEach(listViewModel.items) { item  in
                        ListRowView(item: item)
                            .onTapGesture {
                                withAnimation(.linear) {
                                    listViewModel.updateItem(item: item)
                                }
                            }
                            .transition(.opacity.animation(.easeInOut(duration: 3.0)))
                    }
                    .onDelete(perform: listViewModel.deleteItem)
                    .onMove(perform: listViewModel.moveItem)
                }
                .listStyle(.plain)
                .refreshable {
                    listViewModel.getItems()
                }
            }
        }
        .navigationTitle("To Do List ✍️ ")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink("Add") {
                    AddView()
                        .environmentObject(listViewModel)
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button {
                    } label: {
                        Label("Share List", systemImage: "square.and.arrow.up")
                    }
                    Button {
                    } label: {
                        Label("Sort By", systemImage: "folder")
                    }
                    Button {
                    } label: {
                        Label("Print", systemImage: "printer")
                    }
                    Button(role: .destructive) {
                    } label: {
                        Label("Delete List", systemImage: "trash")
                    }
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
