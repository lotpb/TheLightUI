//
//  FormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI

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

    @StateObject private var viewModel: CustomerFormViewModel
    @State private var height = UIScreen.main.bounds.height

    private var themeColor: Color {
        color == 0 ? .purple : .orange
    }

    private var scrollAxes: Axis.Set {
        height > 800 ? [] : .vertical
    }

    init(
        detail: CustomerItem,
        createDate: Date,
        startDate: Date,
        completeDate: Date,
        status: String,
        formService: CustomerFormServicing = FirebaseCustomerFormService()
    ) {
        _viewModel = StateObject(
            wrappedValue: CustomerFormViewModel(
                detail: detail,
                createDate: createDate,
                startDate: startDate,
                completeDate: completeDate,
                status: status,
                formService: formService
            )
        )

        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.lightGray
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    var body: some View {
        NavigationStack {
            formContent
                .navigationTitle("Data Entry")
                .toolbar { toolbarContent }
                .foregroundColor(themeColor)
                .alert("Success", isPresented: $viewModel.showAlertUpdate) {
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
                    TextField("first", text: $viewModel.detail.first)
                        .formStyle()
                        .focused($firstNameInFocus)

                    TextField("last", text: $viewModel.detail.lastname)
                        .formStyle()

                    Divider()

                    HStack {
                        DatePicker("", selection: $viewModel.pickDate, displayedComponents: .date)
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
        Section(header: Text("\(viewModel.detail.formController) Info")) {
            labeledTextField("Address:", placeholder: "address", text: $viewModel.detail.street)
            labeledTextField("City:", placeholder: "city", text: $viewModel.detail.city)

            stateZipRow(state: $viewModel.detail.state, zip: $viewModel.detail.zip)

            labeledTextField("Phone:", placeholder: "phone", text: $viewModel.detail.phone)
            amountRow
            labeledTextField("Email:", placeholder: "email", text: $viewModel.detail.email, keyboardType: .emailAddress)
        }
    }

    private var jobDetailsSection: some View {
        Section {
            Toggle(isOn: $viewModel.activeIsOn) {
                Text(viewModel.activeLabel)
                    .formTextStyle()
            }
            .onChange(of: viewModel.activeIsOn) { _ in
                viewModel.updateActiveStatus()
            }
            .toggleStyle(SwitchToggleStyle(tint: themeColor))

            pickerRow("Salesman:", selection: $viewModel.selectSalesman, items: pickerviewModel.pickSalesman) { tag in
                viewModel.updateSalesman(tag)
            }

            pickerRow("Job:", selection: $viewModel.selectJob, items: pickerviewModel.pickJob, horizontalPadding: 52) { tag in
                viewModel.updateJob(tag)
            }

            pickerRow("Product:", selection: $viewModel.selectProduct, items: pickerviewModel.pickProduct, horizontalPadding: 15) { tag in
                viewModel.updateProduct(tag)
            }

            quantityRow

            pickerRow("Contractor:", selection: $viewModel.selectContractor, items: pickerviewModel.pickContractor, horizontalPadding: -10) { tag in
                viewModel.updateContractor(tag)
            }

            commentsRow
        }
    }

    private var miscSection: some View {
        Section(header: Text("Misc")) {
            labeledTextField("Spouse:", placeholder: "spouse", text: $viewModel.detail.spouse)
            ratingRow
            dateRow("Start:", title: "Start", selection: $viewModel.pickStartDate)
            dateRow("Complete:", title: "Complete", selection: $viewModel.pickCompleteDate)
            labeledTextField("Photo:", placeholder: "photo", text: $viewModel.detail.photo)
        }
    }

    private var amountRow: some View {
        stepperRow(
            "Amount:",
            value: $viewModel.amount,
            keyboardType: .decimalPad,
            increment: viewModel.incrementAmount,
            decrement: viewModel.decrementAmount
        )
    }

    private var quantityRow: some View {
        stepperRow(
            "Quantity:",
            value: $viewModel.quantity,
            keyboardType: .numberPad,
            increment: viewModel.incrementQuantity,
            decrement: viewModel.decrementQuantity
        )
    }

    private var commentsRow: some View {
        HStack {
            Text("Comments:")
                .formTextStyle()
            Spacer()

            TextEditor(text: $viewModel.detail.comments)
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

            Picker("Pick rating here", selection: $viewModel.selectedRate) {
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
                viewModel.saveButtonTapped()
            } label: {
                Text("Save")
                    .fontWeight(.bold)
            }
            .disabled(viewModel.isButtonDisabled)
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

    private func loadFormState() {
        viewModel.loadFormState()

        guard viewModel.shouldFocusFirstName else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            firstNameInFocus = true
            viewModel.consumeFirstNameFocusRequest()
        }
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
        FormUI(detail: .emptyCustomer, createDate: Date(), startDate: Date(), completeDate: Date(), status: "")
            .environmentObject(CustomerData())
            .environmentObject(PickerDataModel())
    }
    .preferredColorScheme(.dark)
}
