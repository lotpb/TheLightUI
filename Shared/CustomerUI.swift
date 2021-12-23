//
//  CustomerUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import UserNotifications


struct CustomerUI: View {
    
    @AppStorage("color") var color: Int?
    @StateObject var viewModel: CustomerData = CustomerData()
    @StateObject var pickerviewModel: PickerDataModel = PickerDataModel()
    
    let db = Firestore.firestore()
    let notificationManager: NotificationManager = NotificationManager.shared
    
    @State private var formController = "Customer"
    @State private var searchText = ""
    @State private var isAddingCust: Bool = false
    @State private var isCommentBtn = false
    ///filter
    @State private var isFavorites = false
    @State private var filter: FilterType = .none
    ///sorting
    @State private var isSortingMenu: Int = 0
    
    @State private var isSortedByName = false
    
    var sortedData: [customerItem] {
        if isSortedByName {
            // sort prospects by name
            return viewModel.items.sorted(by: { $0.lastname < $1.lastname })
        } else {
            // sort prospects by Most recent == from the latest id
            return viewModel.items.reversed()
        }
    }
    
    enum FilterType {
        case none, favorites
    }

    var results: [customerItem] {
        switch filter {
        case .none:
            if searchText.isEmpty {
                return viewModel.items
            } else {
                return viewModel.items.filter { $0.lastname.localizedCaseInsensitiveContains(searchText.localizedLowercase) }
            }
        case .favorites:
            return viewModel.items.filter {
                $0.active != "0"
            }
        }
    }
    
    var body: some View {
        //NavigationView {
            VStack {
                List {
                    if viewModel.isLoading {
                        ProgressView("Loading Customers...")
                    } else {
                        if self.viewModel.items.isEmpty {
                            Text("No Customers")
                        } else {
                            Toggle(isOn: $isFavorites) {
                                let countItem = viewModel.items.count
                                Text("\(countItem) ") + 
                                Text("Active Only")
                            }
                            .onChange(of: isFavorites) {_ in
                                if isFavorites {
                                    filter = .favorites
                                } else {
                                    filter = .none
                                }
                            }
                            .toggleStyle(SwitchToggleStyle(tint: self.color == 0 ? Color.purple : Color.orange))
                            
                            .toolbar {
                                ToolbarItem(placement: .automatic) {
                                    Menu {
                                        Picker(selection: $isSortingMenu, label: Text("Sorting options")) {
                                            Label("Date", systemImage: "clock").tag(0)
                                            Label("Name", systemImage: "person").tag(1)
                                            Label("Location", systemImage: "location").tag(2)
                                            Label("Active", systemImage: "folder").tag(3)
                                        }
                                    }
                                    label: {
                                        Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
                                    }
                                }
                            }
                            
                            ForEach(results) { item in
                                NavigationLink(destination: LeadDetailUI(detail: item).environmentObject(pickerviewModel).navigationBarBackButtonHidden(true)) {
                                    CellView(data: item, formController: $formController, showComments: $isCommentBtn)
                                }
                                .swipeActions(edge: .leading) {
                                    Button { notificationManager.deleteNotifications()
                                    } label: {
                                        Label("Mark Contacted", systemImage: "person.crop.circle.fill.badge.checkmark")
                                    }
                                    .tint(.green)
                                    
                                    Button { //Add Notifications For Morning"
                                        var dateComponents = DateComponents()
                                        dateComponents.hour = 8
                                        dateComponents.minute = 30
                                        //dateComponents.weekday = 2
                                        notificationManager.scheduleNotification(title: "Contact \(item.lastname)", body: "Email \(item.email)", categoryIdentifier: "reminder", dateComponents: dateComponents, repeats: true)
                                        
                                    } label: {
                                        Label("Remind Me", systemImage: "bell")
                                    }
                                    .tint(.orange)
                                }
                                ///fix delete
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        withAnimation(.linear(duration: 0.4)) {
                                            //self.viewModel.items.removeAll { $0.id == self.viewModel.items.i
                                        }
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .sheet(isPresented: $isAddingCust ) {
                                    FormUI(detail: item, createDate: Date(), startDate: Date(), completeDate: Date(), status: "New")
                                }
                            }
                            .onDelete { (index) in
                                db.collection("Customers").document(self.viewModel.items[index.last!].id).delete { (error) in
                                    if error != nil{
                                        print((error?.localizedDescription)!)
                                        return
                                    }
                                    self.viewModel.items.remove(atOffsets: index)
                                }
                            }
                            .onMove { index, newOffset in
                                self.viewModel.items.move(fromOffsets: index, toOffset: newOffset)
                            }
                            .onAppear {
                                UIApplication.shared.applicationIconBadgeNumber = 0
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            isAddingCust.toggle()
                        }) {
                            Label("New", systemImage: "plus")
                        }
                        
                        Menu {
                            Picker(selection: $isSortingMenu, label: Text("Sorting options")) {
                                Text("Date").tag(0)
                                Text("Name").tag(1)
                                Text("Location").tag(2)
                                Text("Active").tag(3)
                            }
                        }
                        label: {
                            Label("Sort", systemImage: "line.3.horizontal.decrease.circle")
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
                .navigationBarTitle("Customers", displayMode: .inline)
                //.navigationViewStyle(StackNavigationViewStyle())
                .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
                .refreshable {
                    self.viewModel.fetchData()
                }
            }
        //}
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always)) {
            Text("Balsamo").searchCompletion("Balsamo")
            Text("Rosch").searchCompletion("Rosch")
        }
        .foregroundColor(Color.secondary)
        .onAppear() {
            
        }
        .environmentObject(viewModel)
        .environmentObject(pickerviewModel)
    }
}

struct CellView : View {
    
    @AppStorage("color") var color: Int?
    //@EnvironmentObject var viewModel: CustomerData
    var data : customerItem
    @Binding var formController : String
    @Binding var showComments: Bool
    
    var body : some View {
        VStack {
            HStack {
                VStack {
                    Image("taylor_swift_profile")
                        .resizable()
                        .frame(width: 60, height: 60, alignment: .topLeading)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(.top, 5)
                    Spacer()
                }
                
                VStack(alignment: .leading) {
                    Text(data.lastname)
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(Color.primary)
                        .minimumScaleFactor(0.5)
                        .padding(.top, 3)
                    Spacer()
                    Text(data.address)
                        .font(.subheadline)
                        .foregroundColor(Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    VStack {
                        HStack {
                            Button(action: {
                                
                            }) {
                                Image(systemName: "text.bubble.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
                                    .padding(.leading, 7).padding(.trailing, 20)
                            }
                            .disabled(showComments == false)
                            Button(action: {
                                
                            }) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                    .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
                            }
                        }
                        Spacer()
                    }
                }
                .padding(.leading, 10)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(data.date)
                        .frame(width: 90, height: 25)
                        .font(.caption2)
                        .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
                        .minimumScaleFactor(0.5)
                        .padding(.top, 3)
                    Text("$\(data.amount).00")
                        .frame(width: 90, height: 25, alignment: .center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(Color.primary)
                        .font(.headline)
                    Spacer()
                }
            }
        }
    }
    
    func LoadingComments() {
        if (self.formController == "Customer") {
            if self.data.comments == "" {
                showComments = false
            } else {
                showComments = true
            }
        }
    }

}

struct CustomerUI_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CustomerUI(viewModel: CustomerData())
                .preferredColorScheme(.dark)
        }
    }
}

class CustomerData: ObservableObject {
    
    @Published var items = [customerItem]()
    @Published var isLoading: Bool = false
    
    private let db = Firestore.firestore()
    
    init() {
        fetchData()
    }
    
    func fetchData() {
        let formatter4 = DateFormatter()
        formatter4.dateFormat = "MMM dd yyyy"
        
        let formatter = NumberFormatter()
            formatter.numberStyle = .none
        
        self.items.removeAll()
        db.collection("Customers").order(by: "creationDate", descending: true).addSnapshotListener { (snap, error) in
            DispatchQueue.main.async {
                if error != nil {
                    print((error?.localizedDescription)!)
                    return
                }
                for i in snap!.documentChanges {
                    
                    let id = i.document.documentID
                    let stamp = i.document.get("creationDate") as? Timestamp
                    let active = i.document.get("active") as? String ?? ""
                    let first = i.document.get("first") as? String ?? ""
                    let lastname = i.document.get("lastname") as? String ?? ""
                    let street = i.document.get("street") as? String ?? ""
                    let city = i.document.get("city") as? String ?? ""
                    let state = i.document.get("state") as? String ?? ""
                    let zip = i.document.get("zip") as? String ?? ""
                    let amount = i.document.get("amount") as? NSNumber ?? 0
                    let phone = i.document.get("phone") as? String ?? ""
                    let rate = i.document.get("rate") as? String ?? ""
                    let spouse = i.document.get("spouse") as? String ?? ""
                    let comments = i.document.get("comments") as? String ?? ""
                    let email = i.document.get("email") as? String ?? ""
                    let contractor = i.document.get("contractor") as? String ?? ""
                    let photo = i.document.get("photo") as? String ?? ""
                    let stamp1 = i.document.get("start") as? Timestamp
                    let stamp2 = i.document.get("completion") as? Timestamp
                    let stamp3 = i.document.get("lastUpdate") as? Timestamp
                    let quan = i.document.get("quan") as? NSNumber ?? 0
                    let salesNo = i.document.get("salesNo") as? NSNumber ?? 0
                    let jobNo = i.document.get("jobNo") as? NSNumber ?? 0
                    let prodNo = i.document.get("prodNo") as? NSNumber ?? 0
                    
                    //MasterViewController.numberFormatter.numberStyle = .currency
                    let amountString = formatter.string(from: amount)
                    
                    //MasterViewController.numberFormatter.numberStyle = .none
                    let quanStr = formatter.string(from: quan)
                    let salesStr = formatter.string(from: salesNo)
                    let jobStr = formatter.string(from: jobNo)
                    let prodStr = formatter.string(from: prodNo)
                    
                    let address = city + " " + state + " " + zip
                    
                    let date = formatter4.string(from: stamp?.dateValue() ?? Date())
                    let start = formatter4.string(from: stamp1?.dateValue() ?? Date())
                    let complete = formatter4.string(from: stamp2?.dateValue() ?? Date())
                    let last = formatter4.string(from: stamp3?.dateValue() ?? Date())
                    
                    let l11 = "First"; let l21 = "Rating"
                    let l12 = "Phone"; let l22 = "Salesman";
                    let l13 = "Contractor"; let l23 = "Job"
                    let l14 = "Spouse"; let l24 = "Product";
                    let l15 = "Email"; let l25 = "Quan"
                    let l16 = "Last Updated"; let l26 = "Start"
                    let l17 = "Photo"; let l27 = "Complete"
                    let l1datetext = "Sale Date:"
                    let lnewsTitle = Config.NewsCust
                    let status = "Edit"
                    let formController = "Customer"
                    
                    self.isLoading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.items.append(customerItem(id: id, active: active, first: first, lastname: lastname, address: address, street: street, city: city, state: state, zip: zip, amount: amountString!, date: date, rate: rate, phone: phone, comments: comments, spouse: spouse, email: email, contractor: contractor, photo: photo, last: last, start: start, complete: complete, quan: quanStr!, salesNo: salesStr!, jobNo: jobStr ?? "", prodNo: prodStr ?? "", l11: l11, l12: l12, l13: l13, l14: l14, l15: l15, l16: l16, l17: l17, l21: l21, l22: l22, l23: l23, l24: l24, l25: l25, l26: l26, l27: l27, l1datetext: l1datetext, lnewsTitle: lnewsTitle, status: status, formController: formController))
                        self?.isLoading = false
                    }
                }
            }
        }
    }
}

enum Config {
    static let NewsLead = "Company to expand to a new web advertising directive this week."
    static let NewsCust = "Check our new line of fabulous windows and siding."
    static let NewsVend = "Peter Balsamo Appointed to United's Board of Directors."
    static let NewsEmploy = "Health benifits cancelled immediately, starting today."
    static let BaseUrl = "http://lotpb.github.io/UnitedWebPage/index.html"
}

struct customerItem: Identifiable {
    var id: String
    var active: String
    var first: String
    var lastname: String
    var address: String
    var street: String
    var city: String
    var state: String
    var zip: String
    var amount: String
    var date: String
    var rate: String
    var phone: String
    var comments: String
    var spouse: String
    var email: String
    var contractor: String
    var photo: String
    var last: String
    var start: String
    var complete: String
    var quan: String
    var salesNo: String
    var jobNo: String
    var prodNo: String
    var l11: String; var l12: String
    var l13: String; var l14: String
    var l15: String; var l16: String
    var l17: String; var l21: String
    var l22: String; var l23: String
    var l24: String; var l25: String
    var l26: String; var l27: String
    var l1datetext: String; var lnewsTitle: String
    var status: String; var formController: String
}

class PickerDataModel: ObservableObject {
    
    @Published var pickSalesman: [String] = []
    @Published var pickJob: [String] = []
    @Published var pickProduct: [String] = []
    @Published var pickContractor: [String] = []
    @Published var pickRate: [String] = []
    
    init() {
        getData()
    }
    
    func getData() {
        //self.pickCallback.append(contentsOf: ["", "Sold", "follow", "Call back", "Looks Good", "Bought", "Dead", "Cancelled", "future"]
        self.pickSalesman.append(contentsOf: [
            "", "Peter Balsamo", "Adam Monteleone", "John Pellegrino", "Mike Agunzo"
        ])
        self.pickJob.append(contentsOf: [
            "", "Windows", "Siding", "Doors", "Roofing"
        ])
        self.pickProduct.append(contentsOf: [
            "", "Alside", "Andersen", "Ideal", "Marvin"
        ])
        self.pickContractor.append(contentsOf: [
            "", "A & S Home Improvement", "Islandwide Gutters", "Ashland Home Improvement", "John Kat Windows", "Jose Rosa", "Peter Balsamo"
        ])
        self.pickRate.append(contentsOf: [
            "5", "4","1"
        ])
    }
}

