//
//  ListView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI


struct ListView: View {
    
    @StateObject var listViewModel : ListViewModel = ListViewModel()
    //@EnvironmentObject var listViewModel: ListViewModel
    @State private var isCompleted = false
    @State private var isMenu = false

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
                            .toolbar {
                                ToolbarItem(placement: .automatic) {
                                    Menu {
                                        Picker(selection: $isMenu, label: Text("Show List Info")) {
                                            Label("Share List", systemImage: "square.and.arrow.up").tag(0)
                                            Label("Sort By", systemImage: "folder").tag(1)
                                            Label("Print", systemImage: "printer").tag(2)
                                            Button(role: .destructive, action: { }) {
                                                    Label("Delete List", systemImage: "trash").tag(3)
                                            }
                                        }
                                    }
                                    label: {
                                        Label("", systemImage: "bell")
                                    }
                                }
                            }

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
                .listStyle(PlainListStyle())
                .refreshable {
                    self.listViewModel.getItems()
                }
            }
        }
        .navigationTitle("To Do List ✍️ ")
        .navigationBarItems(
            leading: EditButton(),
            trailing: NavigationLink("Add",
            destination: AddView().environmentObject(ListViewModel())))
    }
    
}


struct ListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ListView()
        }
        .environmentObject(ListViewModel())
    }
}
