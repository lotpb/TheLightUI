//
//  FormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

// Customer data entry form with profile, contact info, job details, and misc fields.

import SwiftUI

///
// FormUI
// Presents a multi-section form for creating or editing a customer record.
// Uses a view model to manage form state, validation, and persistence.
///
struct FormUI: View {
    // Layout constants for sizing fields and controls.
    fileprivate enum Layout {
        static let avatarSize: CGFloat = 75
        static let labelWidth: CGFloat = 100
        static let stateFieldWidth: CGFloat = 50
        static let zipLabelWidth: CGFloat = 8
        static let zipLabelLeadingPadding: CGFloat = 50
        static let stepperFieldMinWidth: CGFloat = 80
        static let stepperFieldMaxWidth: CGFloat = 100
    }

    // Persisted theme color choice.
    @AppStorage("color") private var color: Int?
    // Shared picklist values used by multiple pickers.
    @Environment(PickerDataModel.self) private var pickerviewModel
    // Dismiss action from the environment.
    @Environment(\.dismiss) private var dismiss
    // Controls initial focus to the first name field.
    @FocusState private var firstNameInFocus: Bool

    // View model that holds all form data and business logic.
    @State private var viewModel: CustomerFormViewModel

    // Derive the active theme color from settings.
    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    // Initialize the view model and configure UISegmentedControl appearance.
    init(
        detail: CustomerItem,
        createDate: Date,
        startDate: Date,
        completeDate: Date,
        mode: CustomerFormMode,
        formService: CustomerFormServicing = FirebaseCustomerFormService()
    ) {
        _viewModel = State(
            initialValue: CustomerFormViewModel(
                detail: detail,
                createDate: createDate,
                startDate: startDate,
                completeDate: completeDate,
                mode: mode,
                formService: formService
            )
        )

        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.lightGray
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }

    var body: some View {
        // Embed form in a navigation stack for title/toolbar/alerts.
        NavigationStack {
            formContent
                .navigationTitle("Data Entry")
                // Toolbar with Close and Save actions.
                .toolbar { toolbarContent }
                .foregroundColor(themeColor)
                // Success alert displayed after saving.
                .alert("Success", isPresented: $viewModel.showAlertUpdate) {
                    Button("Ok") {
                        dismiss()
                    }
                } message: {
                    Text("Record updated successfully")
                }
        }
        // Accent/tint color for controls.
        .accentColor(themeColor)
    }

    // Main form content with sections.
    private var formContent: some View {
        Form {
            // Section: profile image, first/last name, and created date.
            profileSection
            // Section: address, city, state/zip, phone, amount, email.
            customerInfoSection
            // Section: active toggle, pickers (salesman/job/product/contractor), quantity, and comments.
            jobDetailsSection
            // Section: spouse, rating, start/complete dates, and photo URL/name.
            miscSection
        }
        .font(.system(size: 20.0))
        // Load initial state and optionally focus the first name field.
        .onAppear(perform: loadFormState)
    }

    private var profileSection: some View {
        // Section: profile image, first/last name, and created date.
        Section {
            HStack {
                VStack(spacing: 5) {
                    Image("taylor_swift_profile")
                        .resizable()
                        .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(.trailing, 5)

                    // Placeholder for editing the profile photo.
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

                    // Creation date (or primary date) picker.
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
        // Section: address, city, state/zip, phone, amount, email.
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
        // Section: active toggle, pickers (salesman/job/product/contractor), quantity, and comments.
        Section {
            Toggle(isOn: $viewModel.activeIsOn) {
                Text(viewModel.activeLabel)
                    .formTextStyle()
            }
            // Persist active state to the underlying model.
            .onChange(of: viewModel.activeIsOn) { oldValue, newValue in
                viewModel.updateActiveStatus()
            }
            .toggleStyle(SwitchToggleStyle(tint: themeColor))

            // Salesman picklist.
            pickerRow("Salesman:", selection: $viewModel.selectSalesman, items: pickerviewModel.pickSalesman) { tag in
                viewModel.updateSalesman(tag)
            }

            // Job type picklist.
            pickerRow("Job:", selection: $viewModel.selectJob, items: pickerviewModel.pickJob, horizontalPadding: 52) { tag in
                viewModel.updateJob(tag)
            }

            // Product picklist.
            pickerRow("Product:", selection: $viewModel.selectProduct, items: pickerviewModel.pickProduct, horizontalPadding: 15) { tag in
                viewModel.updateProduct(tag)
            }

            // Quantity stepper.
            quantityRow

            // Contractor picklist.
            pickerRow("Contractor:", selection: $viewModel.selectContractor, items: pickerviewModel.pickContractor, horizontalPadding: -10) { tag in
                viewModel.updateContractor(tag)
            }

            // Free-form comments.
            commentsRow
        }
    }

    private var miscSection: some View {
        // Section: spouse, rating, start/complete dates, and photo URL/name.
        Section(header: Text("Misc")) {
            labeledTextField("Spouse:", placeholder: "spouse", text: $viewModel.detail.spouse)
            ratingRow
            dateRow("Start:", title: "Start", selection: $viewModel.pickStartDate)
            dateRow("Complete:", title: "Complete", selection: $viewModel.pickCompleteDate)
            labeledTextField("Photo:", placeholder: "photo", text: $viewModel.detail.photo)
        }
    }

    // Amount stepper with decimal keyboard.
    private var amountRow: some View {
        stepperRow(
            "Amount:",
            value: $viewModel.amount,
            keyboardType: .decimalPad,
            increment: { viewModel.incrementAmount() },
            decrement: { viewModel.decrementAmount() }
        )
    }

    // Quantity stepper with numeric keyboard.
    private var quantityRow: some View {
        stepperRow(
            "Quantity:",
            value: $viewModel.quantity,
            keyboardType: .numberPad,
            increment: { viewModel.incrementQuantity() },
            decrement: { viewModel.decrementQuantity() }
        )
    }

    // Multiline text editor for comments.
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

    // Segmented picker for star rating.
    private var ratingRow: some View {
        HStack {
            Text("Rating: **\(Image(systemName: "star"))**")
                .formTextStyle()
                .imageScale(.small)
                .symbolVariant(.fill)
                .foregroundStyle(.yellow)

            Picker("Pick rating here", selection: $viewModel.selectedRate) {
                ForEach(pickerviewModel.pickRate, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .foregroundColor(themeColor)
        }
    }

    // Toolbar actions: Close (dismiss) and Save (via view model).
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
            // Disabled until the view model deems the form valid.
            Button {
                viewModel.saveButtonTapped()
            } label: {
                Text("Save")
                    .fontWeight(.bold)
            }
            .disabled(viewModel.isButtonDisabled)
        }
    }

    // Reusable labeled text field row with consistent styling.
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

    // Reusable picker row that forwards selection changes via a callback.
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
            .onChange(of: selection.wrappedValue) { oldValue, newValue in
                onChange(newValue)
            }
        }
    }

    // Reusable date row with a hidden label.
    private func dateRow(_ label: String, title: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .formTextStyle()
            Spacer()

            DatePicker(title, selection: selection, displayedComponents: .date)
                .labelsHidden()
        }
    }

    // Reusable stepper row with inlined text field and increment/decrement handlers.
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
                TextField(label, value: value, formatter: AppNumberFormatters.integer)
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

    // Combined state/zip inputs with fixed label widths for alignment.
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

    // Initialize form values and optionally request focus on the first name field after a short delay.
    private func loadFormState() {
        viewModel.loadFormState()

        guard viewModel.shouldFocusFirstName else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }

            firstNameInFocus = true
            viewModel.consumeFirstNameFocusRequest()
        }
    }
}

// Common text field styling for the form.
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

// Common label styling used throughout the form.
private extension Text {
    func formTextStyle() -> some View {
        self
            .font(.system(size: 18.0))
            .bold()
            .frame(width: FormUI.Layout.labelWidth, alignment: .leading)
            .textSelection(.enabled)
    }

    // Styling for picker text to align and scale properly.
    func pickerTextStyle() -> some View {
        self
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

// Preview: form in dark mode with sample environment objects.
#Preview("Form - Dark") {
    NavigationStack {
        FormUI(
            detail: .emptyCustomer,
            createDate: Date(),
            startDate: Date(),
            completeDate: Date(),
            mode: .new,
            formService: PreviewCustomerFormService()
        )
        .environment(CustomerData(customerService: PreviewCustomerService()))
            .environment(PickerDataModel())
    }
    .preferredColorScheme(.dark)
}

