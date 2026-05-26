//
//  FormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct FormUI: View {
    fileprivate enum Layout {
        static let avatarSize: CGFloat = 75
        static let labelWidth: CGFloat = 100
        static let stateFieldWidth: CGFloat = 50
        static let zipLabelWidth: CGFloat = 8
        static let zipLabelLeadingPadding: CGFloat = 50
        static let stepperFieldMinWidth: CGFloat = 80
        static let stepperFieldMaxWidth: CGFloat = 100
    }

    @AppStorage("color") private var color: Int?
    @EnvironmentObject private var pickerviewModel: PickerDataModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var firstNameInFocus: Bool

    private let db = Firestore.firestore()

    @State private var detail: customerItem
    @State private var showAlertUpdate = false
    @State private var activeIsOn = true
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
    @State private var quanStr = 0

    private var isButtonDisabled: Bool {
        detail.first.isEmpty
    }

    private var themeColor: Color {
        color == 0 ? .purple : .orange
    }

    private var scrollAxes: Axis.Set {
        height > 800 ? [] : .vertical
    }

    init(detail: customerItem, createDate: Date, startDate: Date, completeDate: Date, status: String) {
        self._detail = State(initialValue: detail)
        self._pickDate = State(initialValue: createDate)
        self._pickStartDate = State(initialValue: startDate)
        self._pickCompleteDate = State(initialValue: completeDate)
        self._status = State(initialValue: status)

        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.lightGray
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Data Entry")
                .toolbar { toolbarContent }
                .foregroundColor(themeColor)
                .alert("Success", isPresented: $showAlertUpdate) {
                    Button("Ok") {
                        dismiss()
                    }
                } message: {
                    Text("Record updated successfully")
                }
        }
        .accentColor(themeColor)
    }

    private var formContent: some View {
        VStack {
            ScrollView(scrollAxes, showsIndicators: false) {
                VStack {
                    Form {
                        profileSection
                        customerInfoSection
                        jobDetailsSection
                        miscSection
                    }
                    .font(.system(size: 20.0))
                    .padding(.top, -100)
                }
                .onAppear(perform: loadFormState)
            }
        }
    }

    private var profileSection: some View {
        Section {
            HStack {
                VStack(spacing: 5) {
                    Image("taylor_swift_profile")
                        .resizable()
                        .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(.trailing, 5)

                    Button {} label: {
                        Text("Edit")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(themeColor)
                    }
                    .padding(.top, 8)
                }
                .padding(.leading, -5)

                Divider()
                Spacer()

                VStack(spacing: 12) {
                    TextField("first", text: $detail.first)
                        .formStyle()
                        .focused($firstNameInFocus)

                    TextField("last", text: $detail.lastname)
                        .formStyle()

                    Divider()

                    HStack {
                        DatePicker("", selection: $pickDate, displayedComponents: .date)
                            .clipped()
                            .labelsHidden()

                        Spacer()
                    }
                }
                .multilineTextAlignment(.leading)
            }
            .padding(.bottom, 6)
            .padding(.top, 6)
        }
        .font(.headline)
    }

    private var customerInfoSection: some View {
        Section(header: Text("\(detail.formController) Info")) {
            labeledTextField("Address:", placeholder: "address", text: $detail.street)
            labeledTextField("City:", placeholder: "city", text: $detail.city)

            stateZipRow(state: $detail.state, zip: $detail.zip)

            labeledTextField("Phone:", placeholder: "phone", text: $detail.phone)
            amountRow
            labeledTextField("Email:", placeholder: "email", text: $detail.email, keyboardType: .emailAddress)
        }
    }

    private var jobDetailsSection: some View {
        Section {
            Toggle(isOn: $activeIsOn) {
                Text(activeLabel)
                    .formTextStyle()
            }
            .onChange(of: activeIsOn) { _ in
                updateActiveStatus()
            }
            .toggleStyle(SwitchToggleStyle(tint: themeColor))

            pickerRow("Salesman:", selection: $selectSalesman, items: pickerviewModel.pickSalesman) { tag in
                detail.salesNo = "\(tag)"
            }

            pickerRow("Job:", selection: $selectJob, items: pickerviewModel.pickJob, horizontalPadding: 52) { tag in
                detail.jobNo = "\(tag)"
            }

            pickerRow("Product:", selection: $selectProduct, items: pickerviewModel.pickProduct, horizontalPadding: 15) { tag in
                detail.prodNo = "\(tag)"
            }

            quantityRow

            pickerRow("Contractor:", selection: $selectContractor, items: pickerviewModel.pickContractor, horizontalPadding: -10) { tag in
                detail.contractor = "\(tag)"
            }

            commentsRow
        }
    }

    private var miscSection: some View {
        Section(header: Text("Misc")) {
            labeledTextField("Spouse:", placeholder: "spouse", text: $detail.spouse)
            ratingRow
            dateRow("Start:", title: "Start", selection: $pickStartDate)
            dateRow("Complete:", title: "Complete", selection: $pickCompleteDate)
            labeledTextField("Photo:", placeholder: "photo", text: $detail.photo)
        }
    }

    private var amountRow: some View {
        stepperRow(
            "Amount:",
            value: $amountStr,
            keyboardType: .decimalPad,
            increment: { amountStr += 1000 },
            decrement: { amountStr -= 1000 }
        )
    }

    private var quantityRow: some View {
        stepperRow(
            "Quantity:",
            value: $quanStr,
            keyboardType: .numberPad,
            increment: { quanStr += 1 },
            decrement: { quanStr -= 1 }
        )
    }

    private var commentsRow: some View {
        HStack {
            Text("Comments:")
                .formTextStyle()
            Spacer()

            TextEditor(text: $detail.comments)
                .foregroundColor(.primary)
                .lineLimit(2)
        }
    }

    private var ratingRow: some View {
        HStack {
            Text("Rating: **\(Image(systemName: "star"))**")
                .formTextStyle()
                .imageScale(.small)
                .symbolVariant(.fill)

            Picker("Pick rating here", selection: $selectedRate) {
                ForEach(pickerviewModel.pickRate, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .foregroundColor(themeColor)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Label("Close", systemImage: "xmark.circle")
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Button {
                saveButtonTapped()
            } label: {
                Text("Save")
                    .fontWeight(.bold)
            }
            .disabled(isButtonDisabled)
        }
    }

    private func labeledTextField(
        _ label: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack {
            Text(label)
                .formTextStyle()
            Spacer()

            TextField(placeholder, text: text)
                .formStyle()
                .keyboardType(keyboardType)
        }
    }

    private func pickerRow(
        _ title: String,
        selection: Binding<Int>,
        items: [String],
        horizontalPadding: CGFloat = 0,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        HStack {
            Picker(title, selection: selection) {
                ForEach(items.indices, id: \.self) { index in
                    Text(items[index])
                        .pickerTextStyle()
                        .padding(.horizontal, horizontalPadding)
                }
            }
            .onChange(of: selection.wrappedValue) { tag in
                onChange(tag)
            }
        }
    }

    private func dateRow(_ label: String, title: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .formTextStyle()
            Spacer()

            DatePicker(title, selection: selection, displayedComponents: .date)
                .labelsHidden()
        }
    }

    private var activeLabel: String {
        activeIsOn ? "Active:" : "Not Active:"
    }

    private func stepperRow(
        _ label: String,
        value: Binding<Int>,
        minWidth: CGFloat = FormUI.Layout.stepperFieldMinWidth,
        maxWidth: CGFloat = FormUI.Layout.stepperFieldMaxWidth,
        keyboardType: UIKeyboardType = .numberPad,
        increment: @escaping () -> Void,
        decrement: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(label)
                .formTextStyle()
            Spacer()

            Stepper {
                TextField(label, value: value, formatter: FormUI.Formatters.integer)
                    .formStyle()
                    .frame(minWidth: minWidth, maxWidth: maxWidth)
                    .keyboardType(keyboardType)
            } onIncrement: {
                increment()
            } onDecrement: {
                decrement()
            }
        }
    }

    private func stateZipRow(state: Binding<String>, zip: Binding<String>) -> some View {
        HStack {
            Text("State:")
                .formTextStyle()
            Spacer()

            TextField("state", text: state)
                .formStyle()
                .frame(width: Layout.stateFieldWidth)
                .textInputAutocapitalization(.characters)

            Text("Zip:")
                .formTextStyle()
                .frame(width: Layout.zipLabelWidth)
                .padding(.leading, Layout.zipLabelLeadingPadding)

            TextField("zip", text: zip)
                .formStyle()
                .frame(maxWidth: .infinity)
                .keyboardType(.numberPad)

            Spacer()
        }
    }

    private func saveButtonTapped() {
        if status == "New" {
            saveData()
        } else {
            updateData()
        }
    }

    private func updateActiveStatus() {
        detail.active = activeIsOn ? "1" : "0"
    }

    private func loadFormState() {
        amountStr = intValue(from: detail.amount)

        if status == "New" {
            resetTextFields()
            pickDate = Date()
            detail.active = "1"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                firstNameInFocus = true
            }
            return
        }

        selectSalesman = Int(detail.salesNo) ?? 0
        selectJob = Int(detail.jobNo) ?? 0
        selectProduct = Int(detail.prodNo) ?? 0
        quanStr = Int(detail.quan) ?? 0
        selectedRate = detail.rate
        selectContractor = Int(detail.contractor) ?? 0
        syncActiveToggle()
        pickDate = dateValue(from: detail.date)
        pickStartDate = dateValue(from: detail.start)
        pickCompleteDate = dateValue(from: detail.complete)
    }

    private func intValue(from string: String) -> Int {
        return FormUI.Formatters.integer.number(from: string)?.intValue ?? 0
    }

    private func dateValue(from string: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd yyyy"
        return formatter.date(from: string) ?? Date()
    }

    private func syncActiveToggle() {
        activeIsOn = detail.active == "1"
    }

    private func saveData() {
        let salesStr = intValue(from: detail.salesNo)
        let jobStr = intValue(from: detail.jobNo)
        let prodStr = intValue(from: detail.prodNo)

        guard let uid = Auth.auth().currentUser?.uid else { return }
        var ref: DocumentReference? = nil
        ref = db.collection("Customers").addDocument(data: [
            "active": detail.active,
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
            "salesNo": salesStr,
            "jobNo": jobStr,
            "prodNo": prodStr,
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
                DispatchQueue.main.async {
                    resetTextFields()
                    showAlertUpdate = true
                }
                print("Document added with ID: \(ref?.documentID ?? "")")
            }
        }
    }

    private func updateData() {
        let salesStr = intValue(from: detail.salesNo)
        let jobStr = intValue(from: detail.jobNo)
        let prodStr = intValue(from: detail.prodNo)

        db.collection("Customers")
            .document(detail.id)
            .setData([
                "creationDate": Timestamp(date: pickDate),
                "active": detail.active,
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
                "quan": quanStr,
                "rate": selectedRate,
                "salesNo": salesStr,
                "jobNo": jobStr,
                "prodNo": prodStr,
                "start": Timestamp(date: pickStartDate),
                "completion": Timestamp(date: pickCompleteDate),
                "lastUpdate": Timestamp(date: Date()),
                "comments": detail.comments,
                "spouse": detail.spouse,
                "photo": detail.photo
            ]) { error in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }

                DispatchQueue.main.async {
                    resetTextFields()
                    showAlertUpdate = true
                }
            }
    }

    private func resetTextFields() {
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

private extension FormUI {
    enum Formatters {
        static let integer: NumberFormatter = {
            let f = NumberFormatter()
            f.numberStyle = .none
            return f
        }()

        static let decimal: NumberFormatter = {
            let f = NumberFormatter()
            f.numberStyle = .decimal
            f.minimumFractionDigits = 0
            f.maximumFractionDigits = 2
            return f
        }()
    }
}

private extension TextField {
    func formStyle() -> some View {
        self
            .font(.system(size: 20.0))
            .foregroundColor(.primary)
            .frame(minWidth: 50, maxWidth: .infinity)
            .multilineTextAlignment(.leading)
            .textInputAutocapitalization(.sentences)
            .cornerRadius(10)
    }
}

private extension Text {
    func formTextStyle() -> some View {
        self
            .font(.system(size: 18.0))
            .bold()
            .frame(width: FormUI.Layout.labelWidth, alignment: .leading)
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

#Preview("Form - Dark") {
    NavigationStack {
        FormUI(detail: customerItem(id: "", active: "1", first: "Peter", lastname: "Balsamo", address: "Massapequa Ny, 11758", street: "5121 Lakefront Blvd", city: "Bethpage", state: "NY", zip: "11758", amount: "5000", date: "", rate: "5", phone: "", comments: "", spouse: "", email: "", contractor: "", photo: "", last: "", start: "", complete: "", quan: "", salesNo: "", jobNo: "", prodNo: "", l11: "First", l12: "Phone", l13: "Contractor", l14: "Spouse", l15: "Email", l16: "Last Updated", l17: "Photo", l21: "Rating", l22: "Saleman", l23: "Job", l24: "Product", l25: "Quan", l26: "Start", l27: "Completion", l1datetext: "", lnewsTitle: "", status: "New", formController: "Customer"), createDate: Date(), startDate: Date(), completeDate: Date(), status: "")
            .environmentObject(CustomerData())
            .environmentObject(PickerDataModel())
    }
    .preferredColorScheme(.dark)
}
