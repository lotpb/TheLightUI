//
//  CustomerFormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

// Customer data entry form with profile, contact info, job details, and misc fields.

import SwiftUI

///
// CustomerFormUI
// Presents a multi-section form for creating or editing a customer record.
// Uses a view model to manage form state, validation, and persistence.
///
struct CustomerFormUI: View {
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

    private var isLead: Bool {
        CustomerItem.Category.lead.matches(viewModel.detail.category)
    }

    private var isVendor: Bool {
        CustomerItem.Category.vendor.matches(viewModel.detail.category)
    }

    private var isEmployee: Bool {
        CustomerItem.Category.employee.matches(viewModel.detail.category)
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

        // Configure the global segmented-control appearance exactly once,
        // rather than on every initialization of this view.
        Self.configureSegmentedControlAppearance
    }

    // Lazily-initialized once on first access; SwiftUI has no native API for a
    // segmented picker's selected-segment tint, so the UIKit proxy is still required.
    private static let configureSegmentedControlAppearance: Void = {
        UISegmentedControl.appearance().selectedSegmentTintColor = .lightGray
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }()

    var body: some View {
        // Embed form in a navigation stack for title/toolbar/alerts.
        NavigationStack {
            formContent
                .navigationTitle("Data Entry")
                // Toolbar with Close and Save actions.
                .toolbar { toolbarContent }
                .foregroundStyle(themeColor)
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
        .tint(themeColor)
    }

    // Main form content with sections.
    private var formContent: some View {
        Form {
            // Section: profile image, first/last name, and created date.
            profileSection
            // Section: category picklist (drives the main-menu route filters).
            categorySection
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
                    InitialsAvatarView(
                        firstName: viewModel.detail.first,
                        lastName: viewModel.detail.lastname,
                        size: Layout.avatarSize
                    )
                    .overlay { Circle().stroke(.white, lineWidth: 2) }
                    .padding(.trailing, 5)

                    // Placeholder for editing the profile photo.
                    Button {} label: {
                        Text("Edit")
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundStyle(themeColor)
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

                    if !isVendor {
                        TextField("last", text: $viewModel.detail.lastname)
                            .formStyle()
                    }

                    Divider()

                    // Creation date (or primary date) picker.
                    HStack {
                        // Real title so VoiceOver announces the field; labelsHidden keeps it visually unchanged.
                        DatePicker("Created", selection: $viewModel.pickDate, displayedComponents: .date)
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
        Section("Customer Info") {
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
            // Binds straight to the model; the label tracks the same field.
            Toggle(isOn: $viewModel.detail.isActive) {
                Text(viewModel.activeLabel)
                    .formTextStyle()
            }
            // Inherits the theme tint applied via `.tint(themeColor)`.
            .toggleStyle(.switch)

            // Middle, Department, and Rating (employees only).
            if isEmployee {
                labeledTextField("Middle:", placeholder: "middle", text: $viewModel.detail.callback)
                labeledTextField("Department:", placeholder: "department", text: $viewModel.detail.adNo)
                ratingRow
            }

            // Salesman picklist (vendors use a free-text Manager field instead; hidden for employees).
            if isVendor {
                labeledTextField("Manager:", placeholder: "manager", text: $viewModel.detail.callback)
            } else if !isEmployee {
                pickerRow("Salesman:", selection: $viewModel.detail.salesIndex, items: pickerviewModel.pickSalesman)
            }

            // Job type picklist (vendors use a free-text Profession field instead; hidden for employees).
            if isVendor {
                labeledTextField("Profession:", placeholder: "profession", text: $viewModel.detail.lastname)
                ratingRow
            } else if !isEmployee {
                pickerRow("Job:", selection: $viewModel.detail.jobIndex, items: pickerviewModel.pickJob)
            }

            // Product picklist (not shown for employees or vendors).
            if !isEmployee && !isVendor {
                pickerRow("Product:", selection: $viewModel.detail.productIndex, items: pickerviewModel.pickProduct)
            }

            // Quantity stepper (not shown for employees or vendors).
            if !isEmployee && !isVendor {
                quantityRow
            }

            // Contractor picklist (not shown for leads, employees, or vendors).
            if !isLead && !isEmployee && !isVendor {
                pickerRow("Contractor:", selection: $viewModel.detail.contractorIndex, items: pickerviewModel.pickContractor)
            }

            // Free-form comments.
            commentsRow

            // Callback disposition (not shown for employees or vendors).
            if !isEmployee && !isVendor {
                HStack(spacing: 0) {
                    Text("Callback:")
                        .formTextStyle()
                    Picker("Callback:", selection: $viewModel.detail.callback) {
                        ForEach(pickerviewModel.pickCallback, id: \.self) { value in
                            Text(value.isEmpty ? "None" : value)
                                .pickerTextStyle()
                                .tag(value)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .tint(Color.primary)
                    Spacer()
                }
            }
        }
    }

    private var miscSection: some View {
        // Section: spouse, rating, start/complete dates, and photo URL/name.
        Section("Misc") {
            labeledTextField(isVendor ? "Web Page:" : isEmployee ? "Social Security:" : "Spouse:", placeholder: isVendor ? "web page" : isEmployee ? "social security" : "spouse", text: $viewModel.detail.spouse)
            if !isEmployee && !isVendor {
                ratingRow
            }
            if !isVendor {
                dateRow("Start:", title: "Start", selection: $viewModel.pickStartDate)
            }
            if !isLead && !isVendor {
                dateRow("Complete:", title: "Complete", selection: $viewModel.pickCompleteDate)
            }
            labeledTextField("Photo:", placeholder: "photo", text: $viewModel.detail.photo)
            if !isEmployee && !isVendor {
                HStack(spacing: 0) {
                    Text("Advertiser:")
                        .formTextStyle()
                    Picker("Advertiser:", selection: $viewModel.detail.adNo) {
                        ForEach(pickerviewModel.pickAdvertiser, id: \.self) { value in
                            Text(value.isEmpty ? "None" : value)
                                .pickerTextStyle()
                                .tag(value)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .tint(Color.primary)
                    Spacer()
                }
            }
        }
    }

    // Amount stepper with decimal keyboard.
    private var amountRow: some View {
        stepperRow(
            "Amount:",
            value: $viewModel.detail.amount,
            keyboardType: .decimalPad,
            increment: { viewModel.incrementAmount() },
            decrement: { viewModel.decrementAmount() }
        )
    }

    // Quantity stepper with numeric keyboard.
    private var quantityRow: some View {
        stepperRow(
            "Quantity:",
            value: $viewModel.detail.quantity,
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

            TextField("Comments", text: $viewModel.detail.comments, axis: .vertical)
                .foregroundStyle(Color.primary)
                .lineLimit(2...)
        }
    }

    // Segmented picker for star rating.
    private var ratingRow: some View {
        HStack {
            // "Rating:" uses the accent color; only the star is yellow.
            (
                Text("Rating: ").foregroundStyle(themeColor)
                + Text(Image(systemName: "star.fill")).foregroundStyle(.yellow)
            )
            .formTextStyle()
            .imageScale(.small)

            Picker("Pick rating here", selection: $viewModel.detail.rate) {
                ForEach(pickerviewModel.pickRate, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.segmented)
            .foregroundStyle(themeColor)
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

    // Category picker in its own section, bound to the string value persisted
    // on the model, unlike the index-based picklists below.
    private var categorySection: some View {
        Section {
            categoryRow
        }
    }

    private var categoryRow: some View {
        HStack(spacing: 0) {
            Text("Category:")
                .formTextStyle()

            Picker("Category:", selection: $viewModel.detail.category) {
                ForEach(pickerviewModel.pickCategory, id: \.self) { value in
                    Text(value.isEmpty ? "None" : value)
                        .pickerTextStyle()
                        .tag(value)
                }
            }
            .labelsHidden()
            .fixedSize()
            .tint(Color.primary)

            Spacer()
        }
    }

    // Reusable picker row bound directly to the persisted selection index.
    // Note: the picklists are static and the Int index is the persisted selection
    // value on the model, so indices are the genuine identity here.
    private func pickerRow(
        _ title: String,
        selection: Binding<Int>,
        items: [String]
    ) -> some View {
        HStack(spacing: 0) {
            // Fixed-width label so every picker value aligns at the same leading edge.
            Text(title)
                .formTextStyle()

            Picker(title, selection: selection) {
                ForEach(items.indices, id: \.self) { index in
                    Text(items[index])
                        .pickerTextStyle()
                }
            }
            .labelsHidden()
            .fixedSize()
            .tint(Color.primary)

            Spacer()
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
        keyboardType: UIKeyboardType = .numberPad,
        increment: @escaping () -> Void,
        decrement: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(label)
                .formTextStyle()
            Spacer()

            Stepper {
                // FormatStyle-based field; grouping disabled to match the previous
                // plain-integer NumberFormatter output.
                TextField(label, value: value, format: .number.grouping(.never))
                    .formStyle()
                    .frame(minWidth: Layout.stepperFieldMinWidth, maxWidth: Layout.stepperFieldMaxWidth)
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
            // `Color.primary` (not the hierarchical `.primary`) so the field
            // text uses the adaptive label color, not the inherited theme tint.
            .foregroundStyle(Color.primary)
            .frame(minWidth: 50, maxWidth: .infinity)
            .multilineTextAlignment(.leading)
            .textInputAutocapitalization(.sentences)
            .clipShape(.rect(cornerRadius: 10))
    }
}

// Common label styling used throughout the form.
private extension Text {
    func formTextStyle() -> some View {
        self
            .font(.system(size: 18.0))
            .bold()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: CustomerFormUI.Layout.labelWidth, alignment: .leading)
            .textSelection(.enabled)
    }

    // Styling for picker text to align and scale properly.
    func pickerTextStyle() -> some View {
        self
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

// Preview: form in dark mode with sample environment objects.
#Preview("Form - Dark") {
    NavigationStack {
        CustomerFormUI(
            detail: .emptyCustomer,
            createDate: Date(),
            startDate: Date(),
            completeDate: Date(),
            mode: .new,
            formService: PreviewCustomerFormService()
        )
        .environment(CustomerStore(customerService: PreviewCustomerService()))
        .environment(PickerDataModel())
    }
    .preferredColorScheme(.dark)
}
