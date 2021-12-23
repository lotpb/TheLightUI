//
//  FormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import Firebase
import FirebaseFirestore

extension TextField {
    func formStyle() -> some View {
        self
            .font(.system(size: 20.0))
            .foregroundColor(.primary)
            .frame(minWidth: 50, maxWidth: .infinity)
            .multilineTextAlignment(.leading)
            .autocapitalization(.sentences)
            .cornerRadius(10)
    }
}

extension Text {
    func formTextStyle() -> some View {
        self
            .font(.system(size: 18.0)).bold()
            .frame(width: 100, alignment: .leading)
            .textSelection(.enabled)
    }
    
    func pickerTextStyle() -> some View {
        self
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

struct FormUI: View {
    
    @AppStorage("color") var color: Int?
    @EnvironmentObject var pickerviewModel: PickerDataModel
    @Environment(\.dismiss) var dismiss
    let db = Firestore.firestore()
    
    @State private var detail: customerItem
    
    @State private var showAlertUpdate = false
    
    @State private var activeIsOn = true
    @State private var selDate = Date()
    @State private var height = UIScreen.main.bounds.height
    
    @State private var pickDate: Date
    @State private var pickStartDate: Date
    @State private var pickCompleteDate: Date
    @State private var status: String
    
    @State private var selectedRate = ""
    @State private var selectContractor = 0
    @State private var selectSalesman = 0
    @State private var selectJob = 0
    @State private var selectProduct = 0
    
    @State private var amountStr = 0
    @State private var quanStr: Int = 0
    
    //@State var navigateNext = false
    
    ///disabe save button ot workinh
    private var isButtonDisabled: Bool {
        detail.first.isEmpty
        }
    
    @FocusState private var firstNameInFocus: Bool
    
    init(detail: customerItem, createDate: Date, startDate: Date, completeDate: Date, status: String) {
        
        self._detail = State(initialValue: detail)
        self._pickDate = State(initialValue: createDate)
        self._pickStartDate = State(initialValue: startDate)
        self._pickCompleteDate = State(initialValue: completeDate)
        self._status = State(initialValue: status)
        
        //UISegmentedControl.appearance().backgroundColor = .white
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.lightGray
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        //UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.purple], for: .normal)
        //UISegmentedControl.appearance().selectedSegmentTintColor = .orange
        
        let formatter4 = DateFormatter()
        formatter4.dateFormat = "MMM dd yyyy"
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
    }
    
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView(self.height > 800 ? .init() : .vertical, showsIndicators: false) {
                    VStack {
                        Form {
                            Section {
                                HStack {
                                    VStack(spacing: 5) {
                                        Image("taylor_swift_profile")
                                            .resizable()
                                            .frame(width: 75, height: 75)
                                            .clipShape(Circle())
                                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                            .padding(.trailing, 5)
                                        
                                        Button(action: {}, label: {
                                            Text("Edit").font(.callout).fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                                                .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
                                        })
                                            .padding(.top, 8)
                                    }
                                    .padding(.leading, -5)
                                    
                                    Divider()
                                    Spacer()
                                    VStack(spacing: 12) {
                                        TextField("first", text: $detail.first)
                                            .formStyle()
                                            .focused($firstNameInFocus)
                                        TextField("last", text: $detail.lastname).formStyle()
                                        Divider()
                                        HStack {
                                            DatePicker("", selection: $pickDate, displayedComponents: .date)
                                                .clipped()
                                                .labelsHidden()
                                            
                                            Spacer()
                                        }
                                    }
                                    
                                    .multilineTextAlignment(.leading)
                                }.padding(.bottom, 6).padding(.top, 6)
                            }
                            .font(.headline)
                            
                            Section(header: Text("\(detail.formController) Info")) {
                                HStack {
                                    Text("Address:")
                                        .formTextStyle()
                                    Spacer()
                                    TextField("address", text: $detail.street)
                                        .formStyle()
                                }
                                HStack {
                                    Text("City:")
                                        .formTextStyle()
                                    Spacer()
                                    TextField("city", text: $detail.city)
                                        .formStyle()
                                }
                                HStack {
                                    Text("State:")
                                        .formTextStyle()
                                    Spacer()
                                    TextField("state", text: $detail.state)
                                        .formStyle()
                                        .frame(width: 50)
                                        .autocapitalization(.allCharacters)
                                    
                                    Text("Zip:")
                                        .formTextStyle()
                                        .frame(width: 8)
                                        .padding(.leading, 50)
                                    TextField("zip", text: $detail.zip)
                                        .formStyle()
                                        .frame(maxWidth: .infinity)
                                        .keyboardType(.numberPad)
                                    
                                    Spacer()
                                }
                                HStack {
                                    Text("Phone:")
                                        .formTextStyle()
                                    Spacer()
                                    TextField("phone", text: $detail.phone)
                                        .formStyle()
                                    //.keyboardType(.decimalPad)
                                }
                                HStack {
                                    Text("Amount:")
                                        .formTextStyle()
                                    Spacer()
                                    Stepper(
                                        onIncrement: {
                                            amountStr += 1000
                                        },
                                        onDecrement: {
                                            amountStr -= 1000
                                        },
                                        label: {
                                            TextField("amount",  value: $amountStr, formatter: NumberFormatter())
                                                .formStyle()
                                                .frame(minWidth: 80, maxWidth: 100)
                                                .keyboardType(.decimalPad)
                                        })
                                }
                                HStack {
                                    Text("Email:")
                                        .formTextStyle()
                                    Spacer()
                                    TextField("email", text: $detail.email)
                                        .formStyle()
                                        .keyboardType(.emailAddress)
                                }
                            }
                            
                            Section {
                                HStack {
                                    Toggle(isOn: $activeIsOn) {
                                        Text("\(self.activeIsOn == true ? "Active:" : "Not Active:")")
                                            .formTextStyle()
                                    }
                                    .onChange(of: activeIsOn) {_ in
                                        isOnActive()  
                                    }
                                    .toggleStyle(SwitchToggleStyle(tint: self.color == 0 ? Color.purple : Color.orange))
                                }
                                HStack {
                                    Picker("Salesman:", selection: $selectSalesman) {
                                        ForEach(0 ..< pickerviewModel.pickSalesman.count, id: \.self) {
                                            Text(pickerviewModel.pickSalesman[$0])
                                                .pickerTextStyle()
                                        }
                                    }
                                    .onChange(of: selectSalesman) { tag in
                                        detail.salesNo = "\(tag)"
                                    }
                                }
                                HStack {
                                    Picker("Job:", selection: $selectJob) {
                                        ForEach(0 ..< pickerviewModel.pickJob.count, id: \.self) {
                                            Text(pickerviewModel.pickJob[$0])
                                                .pickerTextStyle()
                                                .padding(.horizontal, 52)
                                        }
                                    }
                                    .onChange(of: selectJob) {tag in
                                        detail.jobNo = "\(tag)"
                                    }
                                }
                                HStack {
                                    Picker("Product:", selection: $selectProduct) {
                                        ForEach(0 ..< pickerviewModel.pickProduct.count, id: \.self) {
                                            Text(pickerviewModel.pickProduct[$0])
                                                .pickerTextStyle()
                                                .padding(.horizontal, 15)
                                        }
                                    }
                                    .onChange(of: selectProduct) { tag in
                                        detail.prodNo = "\(tag)"
                                    }
                                }
                                HStack {
                                    Text("Quantity:")
                                        .formTextStyle()
                                    Spacer()
                                    
                                    Stepper(
                                        onIncrement: {
                                            quanStr += 1
                                        },
                                        onDecrement: {
                                            quanStr -= 1
                                        },
                                        label: {
                                            TextField("Quantity", value: $quanStr, formatter: NumberFormatter())
                                                .formStyle()
                                                .frame(minWidth: 80, maxWidth: 100)
                                                .keyboardType(.numberPad)
                                        })
                                }
                                HStack {
                                    Picker("Contractor:", selection: $selectContractor) {
                                        ForEach(0 ..< pickerviewModel.pickContractor.count, id: \.self) {
                                            Text(pickerviewModel.pickContractor[$0])
                                                .pickerTextStyle()
                                                .padding(.horizontal, -10)
                                        }
                                    }
                                    .onChange(of: selectContractor) { tag in
                                        detail.contractor = "\(tag)"
                                    }
                                }
                                HStack {
                                    Text("Comments:")
                                        .formTextStyle()
                                    Spacer()
                                    TextEditor(text: $detail.comments)
                                        .foregroundColor(.primary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Section(header: Text("Misc")) {
                                HStack {
                                    Text("Spouse:")
                                        .formTextStyle()
                                    Spacer()
                                    TextField("spouse", text: $detail.spouse)
                                        .formStyle()
                                }
                                HStack {
                                    Text("Rating: **\(Image(systemName: "star"))**")
                                        .formTextStyle()
                                        .imageScale(.small).symbolVariant(.fill)
//                                        .symbolRenderingMode(.palette)
//                                        .foregroundStyle(Color.purple, Color.blue)
                                    Picker("Pick rating here", selection: $selectedRate) {
                                        ForEach(pickerviewModel.pickRate, id: \.self) {
                                            Text($0)//.font(.headline)
                                        }
                                    }.pickerStyle(SegmentedPickerStyle())
                                    //.font(.title)
                                        .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
                                    
                                }
                                HStack {
                                    Text("Start:")
                                        .formTextStyle()
                                    Spacer()
                                    DatePicker("Start", selection: $pickStartDate, displayedComponents: .date)
                                        .labelsHidden()
                                    
                                }
                                HStack {
                                    Text("Complete:")
                                        .formTextStyle()
                                    Spacer()
                                    DatePicker("Complete", selection: $pickCompleteDate, displayedComponents: .date)
                                        .labelsHidden()
                                }
                                HStack {
                                    Text("Photo:")
                                        .formTextStyle()
                                    Spacer()
                                    TextField("photo", text: $detail.photo)
                                        .formStyle()
                                }
                            }
                        }
                        .font(.system(size: 20.0))
                        .padding(.top, -20)
                    }
                    .onAppear() {
                        
                        let formatter4 = DateFormatter()
                        formatter4.dateFormat = "MMM dd yyyy"
                        
                        let formatter = NumberFormatter()
                        formatter.numberStyle = .none
                        
                        amountStr = formatter.number(from: detail.amount)?.intValue ?? 0
                        
                        if status == "New" {
                            resetTextFields()
                            pickDate = Date()
                            detail.active = "1"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                firstNameInFocus = true
                            }
                        } else {
                            selectSalesman = Int(detail.salesNo) ?? 0
                            selectJob = Int(detail.jobNo) ?? 0
                            selectProduct = Int(detail.prodNo) ?? 0
                            quanStr = Int(detail.quan) ?? 0
                            selectedRate = detail.rate
                            selectContractor = Int(detail.contractor) ?? 0
                            getActive()
                            pickDate = formatter4.date(from: detail.date) ?? Date()
                            pickStartDate = formatter4.date(from: detail.start) ?? Date()
                            pickCompleteDate = formatter4.date(from: detail.complete) ?? Date()
                        }
                    }
                }
            }
            .navigationTitle("Data Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Label("Close", systemImage: "xmark.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if status == "New" {
                            saveData()
                        } else {
                            updateData()
                        }
                        resetTextFields()
                        self.showAlertUpdate.toggle()
                    } label: {
                        Text("Save")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    }
                    .disabled(isButtonDisabled)///not working
                }
                
            }
            .foregroundColor(self.color == 0 ? Color.purple : Color.orange)
            .alert(isPresented: $showAlertUpdate) {
                Alert(
                    title: Text("Success"),
                    message: Text("Record updated successfully"),
                    dismissButton: Alert.Button.default(
                        Text("Ok"), action: {
                            //navigateNext.toggle()
                            dismiss()
                        }
                    )
                )
            }
        }
        .accentColor(self.color == 0 ? Color.purple : Color.orange)
    }
    
    func isOnActive() {
        if activeIsOn == true {
            detail.active = "1"
        } else {
            detail.active = "0"
        }
    }
    
    func getActive() {
        if (self.detail.active == "1") {
            self.activeIsOn.toggle()
        }
    }
    
    func saveData() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        
        let salesStr = formatter.number(from: detail.salesNo)?.intValue ?? 0
        let jobStr = formatter.number(from: detail.jobNo)?.intValue ?? 0
        let prodStr = formatter.number(from: detail.prodNo)?.intValue ?? 0
        
        let uid = Auth.auth().currentUser!.uid
        var ref: DocumentReference? = nil
        ref = db.collection("Customers").addDocument(data: [
            "active": detail.active,
            //"custId": frm12,
            //"custNo": custNo,
            //"leadNo": detail.leadNo,
            "first": detail.first,
            "lastname": detail.lastname,
            "contractor": detail.contractor,
            "street": detail.street,
            "city": detail.city,
            "state": detail.state,
            "zip": detail.zip,
            "phone": detail.phone,
            "amount": amountStr,
            "email": detail.email,
            "rate": selectedRate,
            "salesNo": salesStr ,
            "jobNo": jobStr ,
            "prodNo": prodStr ,
            "quan": quanStr,
            "comments": detail.comments,
            "spouse": detail.spouse,
            "photo": detail.photo,
            "start": Timestamp(date: Date()),
            "completion": Timestamp(date: Date()),
            "lastUpdate": Timestamp(date: Date()),
            "creationDate": Timestamp(date: Date()),
            "uid": uid,
        ]) { error in
            if let error = error {
                print("Error adding document: \(error)")
            } else {
                self.showAlertUpdate.toggle()
                print("Document added with ID: \(ref!.documentID)")
            }
        }
    }
    
    func updateData() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        
        let salesStr = formatter.number(from: detail.salesNo)?.intValue ?? 0
        let jobStr = formatter.number(from: detail.jobNo)?.intValue ?? 0
        let prodStr = formatter.number(from: detail.prodNo)?.intValue ?? 0
        
        let createDate: Date? = pickDate
        let startDate: Date? = pickStartDate
        let completeDate: Date? = pickCompleteDate
        
        db.collection("Customers")
            .document(detail.id)
            .setData(["creationDate": Timestamp(date: createDate ?? Date()), "active": detail.active, "first": detail.first, "lastname": self.detail.lastname, "contractor": self.detail.contractor, "street": detail.street, "city":self.detail.city, "state": self.detail.state, "zip":detail.zip, "phone":self.detail.phone, "amount":amountStr, "email":self.detail.email, "quan": quanStr, "rate": selectedRate, "salesNo": Int(truncating: NSNumber(value: salesStr)), "jobNo": Int(truncating: NSNumber(value: jobStr)), "prodNo": Int(truncating: NSNumber(value: prodStr)), "start": Timestamp(date: startDate ?? Date()),"completion": Timestamp(date: completeDate ?? Date()), "lastUpdate":Timestamp(date:Date()), "comments": self.detail.comments, "spouse": self.detail.spouse, "photo": self.detail.photo]) { (error) in
                if error != nil{
                    print((error?.localizedDescription)!)
                    return
                }
            }
    }
    
    func resetTextFields() {
        detail.first = ""
        detail.lastname = ""
        detail.contractor = ""
        detail.street = ""
        detail.city = ""
        detail.state = ""
        detail.zip = ""
        detail.phone = ""
        detail.amount = ""
        detail.email = ""
        detail.spouse = ""
        detail.photo = ""
        detail.comments = ""
        detail.quan = ""
        detail.rate = ""
        detail.salesNo = ""
        detail.jobNo = ""
        detail.prodNo = ""
        amountStr = 0
    }
}

struct FormUI_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FormUI(detail: customerItem(id: "", active: "1", first: "Peter", lastname: "Balsamo", address: "Massapequa Ny, 11758", street: "", city: "Bethpage", state: "NY", zip: "11758", amount: "5000", date:"", rate: "5", phone: "", comments: "", spouse: "", email: "", contractor: "", photo: "", last: "", start: "", complete: "", quan: "", salesNo: "", jobNo: "", prodNo: "", l11: "First", l12: "Phone", l13: "Contractor", l14: "Spouse", l15: "Email", l16: "Last Updated", l17: "Photo", l21: "Rating", l22: "Saleman", l23: "Job", l24: "Product", l25: "Quan", l26: "Start", l27: "Completion", l1datetext: "", lnewsTitle: "", status: "New", formController: "Customer"), createDate: Date(), startDate: Date(), completeDate: Date(), status: "")
                .preferredColorScheme(.dark)
            //.environmentObject(CustomerData())
        }
    }
}

