//
//  CustomerFormSections.swift
//  TheLightUI
//
//  Section view structs used by CustomerFormUI. Each section owns its own
//  category-state computation and reads PickerDataModel from the environment.
//

import SwiftUI

// MARK: - Profile Section

struct CustomerFormProfileSection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @FocusState.Binding var firstNameInFocus: Bool

    @AppStorage("color") private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }
    private var isVendor: Bool { CustomerItem.Category.vendor.matches(viewModel.detail.category) }

    var body: some View {
        Section {
            HStack {
                VStack(spacing: 5) {
                    InitialsAvatarView(
                        firstName: viewModel.detail.first,
                        lastName: viewModel.detail.lastname,
                        size: 75
                    )
                    .overlay { Circle().stroke(.white, lineWidth: 2) }
                    .padding(.trailing, 5)

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
}

// MARK: - Category Section

struct CustomerFormCategorySection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @Environment(PickerDataModel.self) private var pickerviewModel

    var body: some View {
        Section {
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
    }
}

// MARK: - Contact Info Section

struct CustomerFormContactSection: View {
    @Bindable var viewModel: CustomerFormViewModel

    private var isVendor: Bool { CustomerItem.Category.vendor.matches(viewModel.detail.category) }
    private var isEmployee: Bool { CustomerItem.Category.employee.matches(viewModel.detail.category) }

    var body: some View {
        Section("Customer Info") {
            labeledTextField("Address:", placeholder: "address", text: $viewModel.detail.street)
            labeledTextField("City:", placeholder: "city", text: $viewModel.detail.city)
            stateZipRow(state: $viewModel.detail.state, zip: $viewModel.detail.zip)
            labeledTextField("Phone:", placeholder: "phone", text: $viewModel.detail.phone)
            if !isVendor && !isEmployee {
                stepperRow(
                    "Amount:",
                    value: $viewModel.detail.amount,
                    keyboardType: .decimalPad,
                    increment: { viewModel.incrementAmount() },
                    decrement: { viewModel.decrementAmount() }
                )
            }
            labeledTextField("Email:", placeholder: "email", text: $viewModel.detail.email, keyboardType: .emailAddress)
        }
    }
}

// MARK: - Job Details Section

struct CustomerFormJobSection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @Binding var managingPickerType: PickerType?
    @Environment(PickerDataModel.self) private var pickerviewModel

    @AppStorage("color") private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }
    private var isEmployee: Bool { CustomerItem.Category.employee.matches(viewModel.detail.category) }
    private var isVendor: Bool { CustomerItem.Category.vendor.matches(viewModel.detail.category) }
    private var isLead: Bool { CustomerItem.Category.lead.matches(viewModel.detail.category) }
    private var isCustomer: Bool { CustomerItem.Category.customer.matches(viewModel.detail.category) }
    private var canEditPickers: Bool { isLead || isCustomer }

    var body: some View {
        Section {
            Toggle(isOn: $viewModel.detail.isActive) {
                Text(viewModel.activeLabel)
                    .formTextStyle()
            }
            .toggleStyle(.switch)

            if isEmployee {
                labeledTextField("Middle:", placeholder: "middle", text: $viewModel.detail.callback)
                labeledTextField("Department:", placeholder: "department", text: $viewModel.detail.adNo)
                ratingRow(rate: $viewModel.detail.rate, items: pickerviewModel.pickRate, themeColor: themeColor)
            }

            // Salesman picklist (vendors use a free-text Manager field; hidden for employees).
            if isVendor {
                labeledTextField("Manager:", placeholder: "manager", text: $viewModel.detail.callback)
            } else if !isEmployee {
                if canEditPickers {
                    editablePickerRow("Salesman:", selection: $viewModel.detail.salesIndex, items: pickerviewModel.pickSalesman, themeColor: themeColor) {
                        managingPickerType = .salesman
                    }
                } else {
                    pickerRow("Salesman:", selection: $viewModel.detail.salesIndex, items: pickerviewModel.pickSalesman)
                }
            }

            // Job type picklist (vendors use a free-text Profession field; hidden for employees).
            if isVendor {
                labeledTextField("Profession:", placeholder: "profession", text: $viewModel.detail.lastname)
                ratingRow(rate: $viewModel.detail.rate, items: pickerviewModel.pickRate, themeColor: themeColor)
            } else if !isEmployee {
                if canEditPickers {
                    editablePickerRow("Job:", selection: $viewModel.detail.jobIndex, items: pickerviewModel.pickJob, themeColor: themeColor) {
                        managingPickerType = .job
                    }
                } else {
                    pickerRow("Job:", selection: $viewModel.detail.jobIndex, items: pickerviewModel.pickJob)
                }
            }

            // Product picklist (not shown for employees or vendors).
            if !isEmployee && !isVendor {
                if canEditPickers {
                    editablePickerRow("Product:", selection: $viewModel.detail.productIndex, items: pickerviewModel.pickProduct, themeColor: themeColor) {
                        managingPickerType = .product
                    }
                } else {
                    pickerRow("Product:", selection: $viewModel.detail.productIndex, items: pickerviewModel.pickProduct)
                }
            }

            // Quantity stepper (not shown for employees or vendors).
            if !isEmployee && !isVendor {
                stepperRow(
                    "Quantity:",
                    value: $viewModel.detail.quantity,
                    increment: { viewModel.incrementQuantity() },
                    decrement: { viewModel.decrementQuantity() }
                )
            }

            // Contractor picklist (not shown for leads, employees, or vendors).
            if !isLead && !isEmployee && !isVendor {
                if isCustomer {
                    editablePickerRow("Contractor:", selection: $viewModel.detail.contractorIndex, items: pickerviewModel.pickContractor, themeColor: themeColor) {
                        managingPickerType = .contractor
                    }
                } else {
                    pickerRow("Contractor:", selection: $viewModel.detail.contractorIndex, items: pickerviewModel.pickContractor)
                }
            }

            commentsRow

            // Callback disposition (leads only).
            if isLead {
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

    private var commentsRow: some View {
        HStack(alignment: .top) {
            Text("Comments:")
                .formTextStyle()
            Spacer()
            TextField("comments", text: $viewModel.detail.comments, axis: .vertical)
                .foregroundStyle(Color.primary)
                .lineLimit(2...)
                .textInputAutocapitalization(.never)
        }
    }
}

// MARK: - Misc Section

struct CustomerFormMiscSection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @Binding var managingPickerType: PickerType?
    @Environment(PickerDataModel.self) private var pickerviewModel

    @AppStorage("color") private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }
    private var isEmployee: Bool { CustomerItem.Category.employee.matches(viewModel.detail.category) }
    private var isVendor: Bool { CustomerItem.Category.vendor.matches(viewModel.detail.category) }
    private var isLead: Bool { CustomerItem.Category.lead.matches(viewModel.detail.category) }
    private var isCustomer: Bool { CustomerItem.Category.customer.matches(viewModel.detail.category) }
    private var canEditPickers: Bool { isLead || isCustomer }

    var body: some View {
        Section("Misc") {
            labeledTextField(
                isVendor ? "Web Page:" : isEmployee ? "Social Security:" : "Spouse:",
                placeholder: isVendor ? "web page" : isEmployee ? "social security" : "spouse",
                text: $viewModel.detail.spouse
            )
            if !isEmployee && !isVendor {
                ratingRow(rate: $viewModel.detail.rate, items: pickerviewModel.pickRate, themeColor: themeColor)
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
                    if canEditPickers {
                        Button {
                            managingPickerType = .advertiser
                        } label: {
                            Image(systemName: "pencil.circle")
                                .foregroundStyle(themeColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}
