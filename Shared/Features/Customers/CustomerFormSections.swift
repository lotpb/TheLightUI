//
//  CustomerFormSections.swift
//  TheLightUI
//
//  Section view structs used by CustomerFormUI. Each section owns its own
//  category-state computation and reads PickerDataModel from the environment.
//

import SwiftUI

// MARK: - Category Section

struct CustomerFormCategorySection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @Environment(PickerDataModel.self) private var pickerviewModel

    @AppStorage(SettingsUI.color) private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }

    var body: some View {
        Section(header: FormSectionHeader(title: "STATUS", color: themeColor)) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Category")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    Picker("Category:", selection: $viewModel.detail.category) {
                        ForEach(pickerviewModel.pickCategory, id: \.self) { value in
                            Text(value.isEmpty ? "none" : value)
                                .pickerTextStyle()
                                .tag(value)
                        }
                    }
                    .labelsHidden()
                    .fixedSize()
                    .tint(Color.primary)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    Toggle("", isOn: $viewModel.detail.isActive)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
        }
    }
}

// MARK: - Contact Section

struct CustomerFormContactInfoSection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @FocusState.Binding var firstNameInFocus: Bool

    @AppStorage(SettingsUI.color) private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(PickerDataModel.self) private var pickerviewModel
    private var isVendor: Bool { CustomerItem.Category.vendor.matches(viewModel.detail.category) }
    private var isLead: Bool { CustomerItem.Category.lead.matches(viewModel.detail.category) }
    private var isCustomer: Bool { CustomerItem.Category.customer.matches(viewModel.detail.category) }
    private var isEmployee: Bool { CustomerItem.Category.employee.matches(viewModel.detail.category) }

    var body: some View {
        let phoneBinding = Binding<String>(
            get: { viewModel.detail.phone },
            set: { viewModel.detail.phone = formatPhone($0) }
        )
        Section(header: FormSectionHeader(title: "CONTACT", color: themeColor)) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isVendor ? "Vendor" : "First")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    TextField(isVendor ? "vendor" : "first", text: $viewModel.detail.first)
                        .formStyle()
                        .focused($firstNameInFocus)
                }
                if isVendor {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "phone.fill")
                                .imageScale(.small)
                                .foregroundStyle(viewModel.detail.salesman.lowercased() == "yes" ? Color.green : Color.gray)
                            Text("Callback")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                        }
                        Menu {
                            ForEach(pickerviewModel.pickCallback, id: \.self) { value in
                                Button { viewModel.detail.salesman = value } label: {
                                    Text(value.isEmpty ? "none" : value)
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(viewModel.detail.salesman.isEmpty ? "none" : viewModel.detail.salesman)
                                    .foregroundStyle(viewModel.detail.salesman.isEmpty ? Color.gray : Color.primary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .imageScale(.small)
                                    .foregroundStyle(Color.primary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if !isVendor {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("last", text: $viewModel.detail.lastname)
                            .formStyle()
                    }
                }
            }
            if isLead || isCustomer {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Company Name")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    TextField("company", text: $viewModel.detail.companyName)
                        .formStyle()
                }
            }
            if sizeClass == .regular {
                HStack(spacing: 12) {
                    phoneField(phoneBinding)
                    emailField
                }
            } else {
                phoneField(phoneBinding)
                emailField
            }
            if isVendor {
                webPageField
            }
        }
    }

    private func phoneField(_ binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Phone")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            TextField("(###) ###-####", text: binding)
                .formStyle()
                .keyboardType(.phonePad)
        }
    }

    private var webPageField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Web Page")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            TextField("web page", text: $viewModel.detail.spouse)
                .formStyle()
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Email")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            TextField("email", text: $viewModel.detail.email)
                .formStyle()
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
        }
    }

    private func formatPhone(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let limited = String(digits.prefix(10))
        var result = ""
        for (i, char) in limited.enumerated() {
            switch i {
            case 0: result += "(\(char)"
            case 3: result += ") \(char)"
            case 6: result += "-\(char)"
            default: result += String(char)
            }
        }
        return result
    }
}

// MARK: - Address Section

struct CustomerFormAddressSection: View {
    @Bindable var viewModel: CustomerFormViewModel

    @AppStorage(SettingsUI.color) private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }

    var body: some View {
        Section(header: FormSectionHeader(title: "ADDRESS", color: themeColor)) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Street")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                TextField("address", text: $viewModel.detail.street)
                    .formStyle()
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("City")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    TextField("city", text: $viewModel.detail.city)
                        .formStyle()
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("State")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    TextField("state", text: $viewModel.detail.state)
                        .formStyle()
                        .frame(width: 50)
                        .textInputAutocapitalization(.characters)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Zip")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.secondary)
                    TextField("zip", text: $viewModel.detail.zip)
                        .formStyle()
                        .keyboardType(.numberPad)
                }
            }
        }
    }
}

// MARK: - Job Section

struct CustomerFormJobInfoSection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @Binding var managingPickerType: PickerType?
    @Environment(PickerDataModel.self) private var pickerviewModel

    @AppStorage(SettingsUI.color) private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }
    private var isLead: Bool { CustomerItem.Category.lead.matches(viewModel.detail.category) }
    private var isCustomer: Bool { CustomerItem.Category.customer.matches(viewModel.detail.category) }
    private var isEmployee: Bool { CustomerItem.Category.employee.matches(viewModel.detail.category) }
    private var isVendor: Bool { CustomerItem.Category.vendor.matches(viewModel.detail.category) }
    private var canEditPickers: Bool { isLead || isCustomer }
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if !isEmployee && !isVendor {
            Section(header: FormSectionHeader(title: "JOB", color: themeColor)) {
                if sizeClass == .regular {
                    HStack(spacing: 12) {
                        if isLead { advertiserColumn } else { salesmanColumn }
                        Divider()
                        jobColumn
                    }
                } else {
                    if isLead { advertiserColumn } else { salesmanColumn }
                    jobColumn
                }
                HStack(spacing: 12) {
                    productColumn
                    if !isLead {
                        Divider()
                        contractorColumn
                    }
                }
                HStack(spacing: 12) {
                    amountColumn
                    Divider()
                    quantityColumn
                }
                HStack(spacing: 12) {
                    ratingColumn
                    Divider()
                    callbackColumn
                }
                if isLead { salesmanColumn } else { advertiserColumn }
            }
        }
    }

    private var salesmanColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Salesman")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            HStack(spacing: 6) {
                Menu {
                    ForEach(pickerviewModel.pickSalesman, id: \.self) { value in
                        Button { viewModel.detail.salesman = value } label: {
                            Text(value.isEmpty ? "none" : value)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.detail.salesman.isEmpty ? "none" : viewModel.detail.salesman)
                            .foregroundStyle(viewModel.detail.salesman.isEmpty ? Color.gray : Color.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(Color.primary)
                    }
                }
                Spacer()
                if canEditPickers {
                    Button { managingPickerType = .salesman } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(themeColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var jobColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Job")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            HStack(spacing: 6) {
                Menu {
                    ForEach(pickerviewModel.pickJob, id: \.self) { value in
                        Button { viewModel.detail.job = value } label: {
                            Text(value.isEmpty ? "none" : value)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.detail.job.isEmpty ? "none" : viewModel.detail.job)
                            .foregroundStyle(viewModel.detail.job.isEmpty ? Color.gray : Color.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(Color.primary)
                    }
                }
                Spacer()
                if canEditPickers {
                    Button { managingPickerType = .job } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(themeColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var productColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Product")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            HStack(spacing: 6) {
                Menu {
                    ForEach(pickerviewModel.pickProduct, id: \.self) { value in
                        Button { viewModel.detail.product = value } label: {
                            Text(value.isEmpty ? "none" : value)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.detail.product.isEmpty ? "none" : viewModel.detail.product)
                            .foregroundStyle(viewModel.detail.product.isEmpty ? Color.gray : Color.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(Color.primary)
                    }
                }
                Spacer()
                if canEditPickers {
                    Button { managingPickerType = .product } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(themeColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contractorColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Contractor")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            HStack(spacing: 6) {
                Menu {
                    ForEach(pickerviewModel.pickContractor, id: \.self) { value in
                        Button { viewModel.detail.contractor = value } label: {
                            Text(value.isEmpty ? "none" : value)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.detail.contractor.isEmpty ? "none" : viewModel.detail.contractor)
                            .foregroundStyle(viewModel.detail.contractor.isEmpty ? Color.gray : Color.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(Color.primary)
                    }
                }
                Spacer()
                if isCustomer {
                    Button { managingPickerType = .contractor } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(themeColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var amountColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Amount")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Stepper {
                TextField("", text: Binding(
                    get: { viewModel.detail.amount == 0 ? "" : "\(viewModel.detail.amount)" },
                    set: { viewModel.detail.amount = Int($0) ?? 0 }
                ))
                .formStyle()
                .frame(minWidth: 60, maxWidth: 80)
                .keyboardType(.decimalPad)
            } onIncrement: {
                viewModel.incrementAmount()
            } onDecrement: {
                viewModel.decrementAmount()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quantityColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Quantity")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Stepper {
                TextField("", text: Binding(
                    get: { viewModel.detail.quantity == 0 ? "" : "\(viewModel.detail.quantity)" },
                    set: { viewModel.detail.quantity = Int($0) ?? 0 }
                ))
                .formStyle()
                .frame(minWidth: 60, maxWidth: 80)
                .keyboardType(.numberPad)
            } onIncrement: {
                viewModel.incrementQuantity()
            } onDecrement: {
                viewModel.decrementQuantity()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var ratingColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Text("Rating")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary)
                Image(systemName: "star.fill")
                    .imageScale(.small)
                    .foregroundStyle(.yellow)
            }
            Picker("Rating", selection: $viewModel.detail.rate) {
                ForEach(pickerviewModel.pickRate, id: \.self) { Text($0) }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var callbackColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "phone.fill")
                    .imageScale(.small)
                    .foregroundStyle(viewModel.detail.callback.lowercased() == "yes" ? Color.green : Color.gray)
                Text("Callback")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondary)
            }
            Menu {
                ForEach(pickerviewModel.pickCallback, id: \.self) { value in
                    Button { viewModel.detail.callback = value } label: {
                        Text(value.isEmpty ? "none" : value)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.detail.callback.isEmpty ? "none" : viewModel.detail.callback)
                        .foregroundStyle(viewModel.detail.callback.isEmpty ? Color.gray : Color.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var advertiserColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Advertiser")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            HStack(spacing: 6) {
                Menu {
                    ForEach(pickerviewModel.pickAdvertiser, id: \.self) { value in
                        Button { viewModel.detail.adNo = value } label: {
                            Text(value.isEmpty ? "none" : value)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(viewModel.detail.adNo.isEmpty ? "none" : viewModel.detail.adNo)
                            .foregroundStyle(viewModel.detail.adNo.isEmpty ? Color.gray : Color.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .imageScale(.small)
                            .foregroundStyle(Color.primary)
                    }
                }
                Spacer()
                if canEditPickers {
                    Button { managingPickerType = .advertiser } label: {
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(themeColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Job Details Section

struct CustomerFormJobSection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @Binding var managingPickerType: PickerType?
    @Environment(PickerDataModel.self) private var pickerviewModel

    @AppStorage(SettingsUI.color) private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }
    private var isEmployee: Bool { CustomerItem.Category.employee.matches(viewModel.detail.category) }

    private static let payTypeOptions = ["", "Hourly", "Salary", "Commission", "Contract"]
    private static let userRoleOptions = ["", "Admin", "Manager", "Sales", "Support", "Viewer"]
    private static let employeeStatusOptions = ["", "Active", "Inactive", "Leave", "Terminated"]

    var body: some View {
        if isEmployee {
            Section(header: FormSectionHeader(title: "EMPLOYEE INFO", color: themeColor)) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Middle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("middle", text: $viewModel.detail.callback)
                            .formStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Department")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("department", text: $viewModel.detail.adNo)
                            .formStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Rating")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        Image(systemName: "star.fill")
                            .imageScale(.small)
                            .foregroundStyle(.yellow)
                    }
                    Picker("Rating", selection: $viewModel.detail.rate) {
                        ForEach(pickerviewModel.pickRate, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                HStack(spacing: 12) {
                    menuPickerField(
                        label: "Pay Type",
                        value: viewModel.detail.payType,
                        options: Self.payTypeOptions
                    ) { viewModel.detail.payType = $0 }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Commission")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("rate", text: $viewModel.detail.commissionRate)
                            .formStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                HStack(spacing: 12) {
                    menuPickerField(
                        label: "Role",
                        value: viewModel.detail.userRole,
                        options: Self.userRoleOptions
                    ) { viewModel.detail.userRole = $0 }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Last Login")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("date", text: $viewModel.detail.lastLogin)
                            .formStyle()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                menuPickerField(
                    label: "Emp Status",
                    value: viewModel.detail.employeeStatus,
                    options: Self.employeeStatusOptions
                ) { viewModel.detail.employeeStatus = $0 }
            }
        }
    }

    private func menuPickerField(label: String, value: String, options: [String], onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button { onSelect(opt) } label: {
                        Text(opt.isEmpty ? "none" : opt)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(value.isEmpty ? "none" : value)
                        .foregroundStyle(value.isEmpty ? Color.gray : Color.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}

// MARK: - Lead Info Section

struct CustomerFormLeadInfoSection: View {
    @Bindable var viewModel: CustomerFormViewModel

    @AppStorage(SettingsUI.color) private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }
    private var isLead: Bool { CustomerItem.Category.lead.matches(viewModel.detail.category) }

    private static let leadStatusOptions = ["", "New", "Contacted", "Qualified", "Proposal", "Negotiation", "Closed Won", "Closed Lost"]

    var body: some View {
        if isLead {
            Section(header: FormSectionHeader(title: "LEAD INFO", color: themeColor)) {
                leadStatusPicker
                HStack(spacing: 12) {
                    lastContactField
                    attemptsField
                }
                tagsField
            }
        }
    }

    private var leadStatusPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Status")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Menu {
                ForEach(Self.leadStatusOptions, id: \.self) { opt in
                    Button { viewModel.detail.leadStatus = opt } label: {
                        Text(opt.isEmpty ? "none" : opt)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(viewModel.detail.leadStatus.isEmpty ? "none" : viewModel.detail.leadStatus)
                        .foregroundStyle(viewModel.detail.leadStatus.isEmpty ? Color.gray : Color.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lastContactField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Last Contact")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            TextField("date", text: $viewModel.detail.lastContactDate)
                .formStyle()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var attemptsField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Attempts")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Stepper {
                TextField("", text: Binding(
                    get: { viewModel.detail.contactAttempts == 0 ? "" : "\(viewModel.detail.contactAttempts)" },
                    set: { viewModel.detail.contactAttempts = Int($0) ?? 0 }
                ))
                .formStyle()
                .frame(minWidth: 40, maxWidth: 60)
                .keyboardType(.numberPad)
            } onIncrement: {
                viewModel.detail.contactAttempts += 1
            } onDecrement: {
                if viewModel.detail.contactAttempts > 0 { viewModel.detail.contactAttempts -= 1 }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var tagsField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tags")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            TextField("tag1, tag2", text: Binding(
                get: { viewModel.detail.tags.joined(separator: ", ") },
                set: { viewModel.detail.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
            ))
            .formStyle()
            .textInputAutocapitalization(.never)
        }
    }
}

// MARK: - Misc Section

struct CustomerFormMiscSection: View {
    @Bindable var viewModel: CustomerFormViewModel
    @Binding var managingPickerType: PickerType?
    @Environment(PickerDataModel.self) private var pickerviewModel

    @AppStorage(SettingsUI.color) private var color: Int?
    private var themeColor: Color { AppTheme.accentColor(for: color) }
    private var isEmployee: Bool { CustomerItem.Category.employee.matches(viewModel.detail.category) }
    private var isVendor: Bool { CustomerItem.Category.vendor.matches(viewModel.detail.category) }
    private var isLead: Bool { CustomerItem.Category.lead.matches(viewModel.detail.category) }
    private var isCustomer: Bool { CustomerItem.Category.customer.matches(viewModel.detail.category) }
    private var canEditPickers: Bool { isLead || isCustomer }

    private static let paymentTermsOptions = ["", "Due on Receipt", "Net 15", "Net 30", "Net 60"]
    private static let leadSourceOptions = ["", "Website", "Referral", "Social Media", "Cold Call", "Walk In", "Other"]
    private static let paymentStatusOptions = ["", "Pending", "Paid", "Overdue", "Cancelled"]
    private static let leadStatusOptions = ["", "New", "Contacted", "Qualified", "Proposal", "Negotiation", "Closed Won", "Closed Lost"]

    @State private var ssnUnlocked = false
    @State private var showPasswordPrompt = false
    @State private var passwordEntry = ""
    @State private var adminPassword: String = ""

    var body: some View {
        let spouseBinding = Binding<String>(
            get: { viewModel.detail.spouse },
            set: { viewModel.detail.spouse = isEmployee ? formatSSN($0) : $0 }
        )
        let driverLicenseBinding = Binding<String>(
            get: { viewModel.detail.driverLicense },
            set: { viewModel.detail.driverLicense = $0.uppercased().filter { $0.isLetter || $0.isNumber } }
        )
        Group {
            if isLead {
                Section(header: FormSectionHeader(title: "DATES", color: themeColor)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Appt Date")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        DatePicker("Appt Date", selection: $viewModel.pickStartDate, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "en_US"))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Follow Up")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        DatePicker("Follow Up", selection: Binding(
                            get: { viewModel.detail.followUpDate ?? Date() },
                            set: { viewModel.detail.followUpDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "en_US"))
                    }
                }
            }
            if isCustomer {
                Section(header: FormSectionHeader(title: "DATES", color: themeColor)) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Start")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            if viewModel.hasPickedStartDate {
                                HStack(spacing: 8) {
                                    DatePicker("Start", selection: $viewModel.pickStartDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .environment(\.locale, Locale(identifier: "en_US"))
                                    Button { viewModel.hasPickedStartDate = false } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Button { viewModel.pickStartDate = Date(); viewModel.hasPickedStartDate = true } label: {
                                    Text("—")
                                        .font(.body)
                                        .foregroundStyle(Color.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Complete")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            if viewModel.hasPickedCompleteDate {
                                HStack(spacing: 8) {
                                    DatePicker("Complete", selection: $viewModel.pickCompleteDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .environment(\.locale, Locale(identifier: "en_US"))
                                    Button { viewModel.hasPickedCompleteDate = false } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Button { viewModel.pickCompleteDate = Date(); viewModel.hasPickedCompleteDate = true } label: {
                                    Text("—")
                                        .font(.body)
                                        .foregroundStyle(Color.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Sale Date")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        DatePicker("Sale Date", selection: $viewModel.pickDate, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "en_US"))
                    }
                }
                Section(header: FormSectionHeader(title: "PERSONAL", color: themeColor)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Spouse")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("spouse", text: $viewModel.detail.spouse)
                            .formStyle()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("photo", text: $viewModel.detail.photo)
                            .formStyle()
                    }
                }
            }
            if isVendor {
                Section(header: FormSectionHeader(title: "JOB INFO", color: themeColor)) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Profession")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("profession", text: $viewModel.detail.profession)
                                .formStyle()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Manager")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("manager", text: $viewModel.detail.manager)
                                .formStyle()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    miscMenuPickerField(label: "Payment Terms", value: viewModel.detail.paymentTerms, options: Self.paymentTermsOptions) {
                        viewModel.detail.paymentTerms = $0
                    }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Tax ID")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("tax id", text: $viewModel.detail.taxId)
                                .formStyle()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Account #")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("account #", text: $viewModel.detail.accountNumber)
                                .formStyle()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("photo", text: $viewModel.detail.photo)
                            .formStyle()
                    }
                }
            }
            if isEmployee {
                Section(header: FormSectionHeader(title: "PERSONAL", color: themeColor)) {
                    if ssnUnlocked {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Social Security")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            TextField("###-##-####", text: spouseBinding)
                                .formStyle()
                                .keyboardType(.numberPad)
                        }
                    } else {
                        ssnLockedRow
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Driver License")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("driver license", text: driverLicenseBinding)
                            .formStyle()
                            .keyboardType(.asciiCapable)
                            .textInputAutocapitalization(.characters)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("photo", text: $viewModel.detail.photo)
                            .formStyle()
                    }
                }
            }
            if isEmployee {
                Section(header: FormSectionHeader(title: "DATES", color: themeColor)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Birth Date")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        DatePicker("Birth Date", selection: $viewModel.pickBirthDate, displayedComponents: .date)
                            .labelsHidden()
                            .environment(\.locale, Locale(identifier: "en_US"))
                    }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Start")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            DatePicker("Start", selection: $viewModel.pickStartDate, displayedComponents: .date)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "en_US"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Termination")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.secondary)
                            if viewModel.hasPickedCompleteDate {
                                HStack(spacing: 8) {
                                    DatePicker("Termination", selection: $viewModel.pickCompleteDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .environment(\.locale, Locale(identifier: "en_US"))
                                    Button { viewModel.hasPickedCompleteDate = false } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(Color.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                Button { viewModel.pickCompleteDate = Date(); viewModel.hasPickedCompleteDate = true } label: {
                                    Text("—")
                                        .font(.body)
                                        .foregroundStyle(Color.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            if isLead {
                Section(header: FormSectionHeader(title: "PERSONAL", color: themeColor)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Spouse")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("spouse", text: $viewModel.detail.spouse)
                            .formStyle()
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Photo")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.secondary)
                        TextField("photo", text: $viewModel.detail.photo)
                            .formStyle()
                    }
                }

            }
            if isCustomer {
                Section(header: FormSectionHeader(title: "ACCOUNT", color: themeColor)) {
                    HStack(spacing: 12) {
                        miscMenuPickerField(label: "Lead Source", value: viewModel.detail.leadSource, options: Self.leadSourceOptions) {
                            viewModel.detail.leadSource = $0
                        }
                        miscMenuPickerField(label: "Payment Terms", value: viewModel.detail.paymentTerms, options: Self.paymentTermsOptions) {
                            viewModel.detail.paymentTerms = $0
                        }
                    }
                    miscMenuPickerField(label: "Payment Status", value: viewModel.detail.paymentStatus, options: Self.paymentStatusOptions) {
                        viewModel.detail.paymentStatus = $0
                    }
                }
            }
            if isLead || isCustomer || isEmployee || isVendor {
                Section(header: FormSectionHeader(title: "COMMENTS", color: themeColor)) {
                    commentsRow
                }
            }
        }
        .alert("Admin Access Required", isPresented: $showPasswordPrompt) {
            SecureField("Password", text: $passwordEntry)
            Button("Unlock") {
                if passwordEntry == adminPassword {
                    ssnUnlocked = true
                }
                passwordEntry = ""
            }
            Button("Cancel", role: .cancel) { passwordEntry = "" }
        } message: {
            Text("Enter administrator password to view Social Security Number.")
        }
        .onAppear {
            adminPassword = SecureSettingsStore.loadString(forKey: SettingsUI.adminPasswordKey, defaultValue: "admin")
        }
    }

    private var ssnLockedRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Social Security")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            HStack {
                if !viewModel.detail.spouse.isEmpty {
                    Text("•••-••-••••")
                        .foregroundStyle(Color.secondary)
                }
                Spacer()
                Button {
                    passwordEntry = ""
                    showPasswordPrompt = true
                } label: {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(themeColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var commentsRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            TextField("comments", text: $viewModel.detail.comments, axis: .vertical)
                .foregroundStyle(Color.primary)
                .lineLimit(2...)
                .textInputAutocapitalization(.never)
        }
    }

    private func formatSSN(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        let limited = String(digits.prefix(9))
        var result = ""
        for (i, char) in limited.enumerated() {
            switch i {
            case 3: result += "-\(char)"
            case 5: result += "-\(char)"
            default: result += String(char)
            }
        }
        return result
    }

    private func miscMenuPickerField(label: String, value: String, options: [String], onSelect: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Menu {
                ForEach(options, id: \.self) { opt in
                    Button { onSelect(opt) } label: {
                        Text(opt.isEmpty ? "none" : opt)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(value.isEmpty ? "none" : value)
                        .foregroundStyle(value.isEmpty ? Color.gray : Color.primary)
                    Image(systemName: "chevron.up.chevron.down")
                        .imageScale(.small)
                        .foregroundStyle(Color.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
