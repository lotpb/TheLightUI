//
//  LeadDetailUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import EventKit

struct ListModel: Identifiable {
    var id = UUID().uuidString
    var name: String
    var label : String
}


struct LeadDetailUI: View {
    @EnvironmentObject var viewModel: CustomerData
    @EnvironmentObject var pickerviewModel: PickerDataModel
    @AppStorage("color") var color: Int?
    @AppStorage("activeColor") var activeColor: Int?
    @Environment(\.dismiss) var dismiss
    let maxWidthForIpad: CGFloat = 700
    
    @State var detail: customerItem
    @State private var showingSold: Bool = false
    @State private var showSheet: Bool = false
    @State private var showFullscreen: Bool = false
    @State private var showActionSheet: Bool = false
    @State private var showActive: Bool = false
    @State private var height = UIScreen.main.bounds.height
    @State private var comments = ""
    @State private var lnewsTitle = ""
    @State private var index = 0
    
    @State private var showPopover = false
    @State var showEmailComposer = false
    
    //@State var dataArray: [ListModel] = []
    
    var body: some View {
        
        let saleNo = Int(detail.salesNo) ?? 0
        let jobNo = Int(detail.jobNo) ?? 0
        let prodNo = Int(detail.prodNo) ?? 0
        let contractNo = Int(detail.contractor) ?? 0
        
        let dataArray = [
            ListModel(name: detail.first, label: detail.l11),
            ListModel(name: detail.phone, label: detail.l12),
            ListModel(name: pickerviewModel.pickContractor[contractNo], label: detail.l13),
            ListModel(name: detail.spouse, label: detail.l14),
            ListModel(name: detail.email, label: detail.l15),
            ListModel(name: detail.last, label: detail.l16),
            ListModel(name: detail.rate, label: detail.l21),
            ListModel(name: pickerviewModel.pickSalesman[saleNo], label: detail.l22),
            ListModel(name: pickerviewModel.pickJob[jobNo], label: detail.l23),
            ListModel(name: pickerviewModel.pickProduct[prodNo], label: detail.l24),
            ListModel(name: "\(detail.quan)", label: detail.l25),
            ListModel(name: detail.start, label: detail.l26),
            ListModel(name: detail.complete, label: detail.l27),
            ListModel(name: detail.photo, label: detail.l17)
        ]
        
        VStack() {
            ScrollView(self.height > 800 ? .init() : .vertical, showsIndicators: true) {
                
                TopViewUI(detail: $detail, showFullscreen: $showFullscreen, showingSold: $showingSold)
                
                ScrollView(self.height > 800 ? .init() : .vertical, showsIndicators: false) {
                    
                    List(dataArray) { customer in
                        CenterViewUI(formData: customer)
                    }
                    .listStyle(.plain)
                    .onAppear() {
                        getSold()
                        getActive()
                    }
                }
                BottomViewUI(detail: $detail, showPopover: $showPopover)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Profile")
        .navigationBarHidden(false)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Label("Close", systemImage: "xmark.circle")
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    showActionSheet.toggle()
                }) {
                    Label("Action", systemImage: "square.and.arrow.up")
                }
                Button(action: {
                    showSheet.toggle()
                }, label: {
                    Text("Edit").fontWeight(.semibold)
                })
            }
        }
        .actionSheet(isPresented: $showActionSheet, content: getActionSheet)
        .sheet(isPresented: $showSheet, content: {
            FormUI(detail: customerItem(id: detail.id, active: detail.active, first: detail.first, lastname: detail.lastname, address: detail.address, street: detail.street, city: detail.city, state: detail.state, zip: detail.zip, amount: detail.amount, date: detail.date, rate: detail.rate, phone: detail.phone, comments: detail.comments, spouse: detail.spouse, email: detail.email, contractor: detail.contractor, photo: detail.photo, last: detail.last, start: detail.start, complete: detail.complete, quan: detail.quan, salesNo: detail.salesNo, jobNo: detail.jobNo, prodNo: detail.prodNo, l11: "", l12: "", l13: "", l14: "", l15: "", l16: "", l17: "", l21: "", l22: "", l23: "", l24: "", l25: "", l26: "", l27: "", l1datetext: "Sale Date:", lnewsTitle: "", status: detail.status, formController: detail.formController), createDate: Date(), startDate: Date(), completeDate: Date(), status: "Edit")
        })
        .sheet(isPresented: $showEmailComposer) {
                    MailView(
                        subject: "Email support",
                        message: "Message",
                        attachment: nil,
                        onResult: { _ in
                             // Handle the result if needed.
                             self.showEmailComposer = false
                        }
                    )
                }
        .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
        .accentColor(self.color == 0 ? Color.purple : Color.orange)
        .navigationViewStyle(StackNavigationViewStyle())
        .frame(maxWidth: maxWidthForIpad)
    }

    func getActionSheet() -> ActionSheet {
        let button1: ActionSheet.Button = .default(Text("Send Message"))
        let button2: ActionSheet.Button = .default(Text("Add to Customer"))
        let button3: ActionSheet.Button = .default(Text("Add to Contact"))
        let button4: ActionSheet.Button = .default(Text("Add Calender Event"))
        let button5: ActionSheet.Button = .default(Text("$ pay"))
        let button6: ActionSheet.Button = .default(Text("Web Page"))
        let button7: ActionSheet.Button = .default(Text("Call Phone"))
        let button8: ActionSheet.Button = .default(Text("Send Email")) {
            showEmailComposer = true
        }
        
        let button9: ActionSheet.Button = .default(Text("Share My Location"))
        let button10: ActionSheet.Button = .cancel()
        
        return ActionSheet(
            title: Text("Pick a menu item"),
            buttons: [button1, button2, button3, button4, button5, button6, button7, button8, button9, button10])
    }

    
    private func getSold() {
        if (self.detail.formController == "Customer") {
            if self.detail.rate == "5" {
                showingSold = true
            } else {
                showingSold = false
            }
        }
    }
    
    private func setupSwitch() {
        if (self.detail.formController == "Leads") {
            if (self.detail.first == "Sold") {
                showingSold = true
            } else {
                showingSold = false
            }
        }
    }
    
    private func getActive() {
        if (self.detail.active == "1") {
            self.activeColor = 1
        } else {
            self.activeColor = 0
        }
    }
    
    func callPhone() {
        
    }
    
    private func getEmail(_ emailfield: NSString) {
        
    }
    
    private func addEvent() {
        
    }
    
    private func createContact() {
        
    }
    
    private func createEvent(_ eventStore: EKEventStore, title: String, startDate: Date, endDate: Date) {
        
    }
    
    private func getBirthday() {
        
    }
}

struct TopViewUI: View {
    
    @AppStorage("color") var color: Int?
    @AppStorage("activeColor") var activeColor: Int?
    
    @Binding var detail: customerItem
    @Binding var showFullscreen: Bool
    @Binding var showingSold: Bool
   
    var body: some View {
        
        VStack(alignment: .trailing, spacing: 13) {
            HStack {
                Text(detail.lastname).font(.system(size: 38, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.1)
                    .padding(.top, 3).padding(.leading, 20).padding(.bottom, -10)
                //.redacted(reason: .placeholder)
                Spacer()
                
                Text(self.activeColor == 0 ? "Follow" : "Following").font(.system(size: 18, weight: .semibold, design: .rounded))
                    .padding(.top, 10)
                
                Button(action: {
                    
                }) {
                    Image(systemName: "star.fill")
                        .frame(width: 21, height: 21)
                        .foregroundColor(self.activeColor == 0 ? Color.secondary : Color.blue)
                        .padding(.top, 7).padding(.trailing, 15)
                }
            }
            
            Divider()
            
            VStack {
                
                HStack {
                    VStack(alignment: .leading, spacing: 0) {
                        //let amountStr = NSDecimalNumber(string: "\(detail.amount).00")
                        Text("$\(detail.amount).00").font(.largeTitle).fontWeight(.semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.9)
                        Spacer()
                        Text(detail.street).font(.system(size: 20, weight: .regular, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        Text(detail.address).font(.system(size: 20, weight: .regular, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                        Spacer()
                        Text(detail.l1datetext).font(.caption2.bold())
                            .foregroundColor(Color(.lightGray))
                        Text(detail.date).font(.headline)
                    }
                    .padding(.leading, 20)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 0) {
                        
                        Image("taylor_swift_profile")
                            .resizable()
                            .frame(width: 115, height: 115)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        
                        Text(detail.id).font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.top, 15)
                    }
                    .frame(width: 120)
                    .padding(.trailing, 15)
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Toggle("", isOn: $showingSold.animation(.spring()))
                                .frame(width:80)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .cornerRadius(10)
                            
                            if showingSold {
                                Text("Priority").font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .frame(width: 75, height: 30)
                                    .background(Color.red.cornerRadius(10))
                                    .foregroundColor(.white)
                                    .padding(.leading, 10)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack {
                        Button {
                            showFullscreen.toggle()
                        } label: {
                            Text("Map").font(.headline).fontWeight(.semibold)
                                .frame(maxWidth: 130)
                        }
                        .tint(.blue)
                        .foregroundColor(.white)
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.automatic)
                        .controlSize(.regular)
                    }
                    .frame(width: 120)
                    .padding(.trailing, 20)
                }
                .padding(.bottom, 20)
            }
            .fullScreenCover(isPresented: $showFullscreen, content: {
                MapUI(mapstreet: detail.street, mapcity: detail.city, mapstate: detail.state, mapzip: detail.zip, travelTime: 0.00, distance: 0.00)
            })
        }
        .foregroundColor(self.color == 0 ? Color.white : Color.black)
        .background(self.color == 0 ? Color.purple : Color.orange)
        .clipShape(CustomShape(corner: .bottomLeft, radii: 55))
        .shadow(radius: 10)
    }
}

struct CenterViewUI : View {
    
    var formData: ListModel
    @AppStorage("color") var color: Int?
    
    var body: some View {
        HStack {
            Text(formData.label)
                .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
            Spacer()
            Text(formData.name)
                .foregroundColor(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .font(.body)
        //.frame(height: 20)
    }
}

struct BottomViewUI : View {
    
    @AppStorage("color") var color: Int?
    @Binding var detail : customerItem
    @Binding var showPopover: Bool
    
    var body : some View {
        HStack {
            VStack {
                VStack() {
                    HStack {
                        Text(detail.lnewsTitle)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: 55, alignment: .topLeading)
                            .lineLimit(2)
                            .font(.body)
                    }
                    
                    HStack(spacing: 0) {
                        Text("Comments").foregroundColor(self.color == 0 ? Color.purple : Color.orange)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button {
                            showPopover = true
                        } label: {
                            Text("Read more").foregroundColor(self.color == 0 ? Color.purple : Color.orange)
                                .lineLimit(1)
                        }
                        .popover(isPresented: $showPopover) {
                            PopoverContent(detail: $detail)
                        }
                    }
                    .padding(.top, -16)
                    .font(.caption)
                    
                    Text(detail.comments)
                        .foregroundColor(Color.primary)
                        .frame( maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .topLeading)
                        .cornerRadius(10)
                        .textSelection(.enabled)
                }
                .padding(.leading, 20).padding(.trailing, 20)
            }
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: 100)
        }
    }
}

struct PopoverContent: View {
    
    @Binding var detail : customerItem
    private var formattedDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter.string(from: Date())
    }
    
    var body: some View {
        VStack {
            Text(formattedDate)
                .font(.title2).padding(.bottom, 15)
                .lineLimit(1)
                .minimumScaleFactor(0.1)
            Text("Comments:")
                .font(.title3).fontWeight(.bold)
                .padding(.bottom, 10)
            TextEditor(text: $detail.comments)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(width: 350, height: 200)
    }
}

struct LeadDetailUI_Previews: PreviewProvider {
    static var previews: some View {

            LeadDetailUI(detail: customerItem(
                id: "8899999", active: "1", first: "Peter", lastname: "Balsamo", address: "Massapequa Ny 11758", street: "1142 Hicksville Road", city: "", state: "", zip: "", amount: "$5000.00", date:"Mar 30 2021", rate: "5", phone: "516-241-4786", comments: "Hello", spouse: "Janet", email: "email.com", contractor: "Jose", photo: "none", last: "Mar 12 1989", start: "Mar 7 2090", complete: "Nov 23 1958", quan: "5", salesNo: "", jobNo: "", prodNo: "", l11: "First", l12: "Phone", l13: "Contractor", l14: "Spouse", l15: "Email", l16: "Last Updated", l17: "Photo", l21: "Rating", l22: "Salesman", l23: "Job", l24: "Product", l25: "Quan", l26: "Start", l27: "Completion", l1datetext: "Sale Date:", lnewsTitle: "Comment News:", status: "Edit", formController: "Customer"
            ))
                //.environmentObject(pickerviewModel)
                .preferredColorScheme(.dark)
       }
}
