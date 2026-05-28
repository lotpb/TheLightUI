//
//  LeadDetailUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI
#if canImport(MessageUI)
import MessageUI
#endif

struct LeadDetailUI: View {
    @EnvironmentObject private var pickerviewModel: PickerDataModel
    @AppStorage("color") private var color: Int?
    @AppStorage("activeColor") private var activeColor: Int?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let maxWidthForIpad: CGFloat = 700
    private let formService: CustomerFormServicing

    @State var detail: CustomerItem
    @State private var showFullscreen = false
    @State private var showPopover = false
    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: Identifiable {
        case edit
        case email
        case message

        var id: Self { self }
    }

    init(
        detail: CustomerItem,
        formService: CustomerFormServicing = FirebaseCustomerFormService()
    ) {
        self._detail = State(initialValue: detail)
        self.formService = formService
    }

    private var themeColor: Color {
        color == 0 ? .purple : .orange
    }

    private var detailFields: [CustomerDetailField] {
        [
            CustomerDetailField(name: detail.first, label: CustomerLabels.first),
            CustomerDetailField(name: detail.phone, label: CustomerLabels.phone),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickContractor, at: detail.contractorIndex), label: CustomerLabels.contractor),
            CustomerDetailField(name: detail.spouse, label: CustomerLabels.spouse),
            CustomerDetailField(name: detail.email, label: CustomerLabels.email),
            CustomerDetailField(name: detail.formattedLastUpdateDate, label: CustomerLabels.lastUpdated),
            CustomerDetailField(name: detail.rate, label: CustomerLabels.rating),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickSalesman, at: detail.salesIndex), label: CustomerLabels.salesman),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickJob, at: detail.jobIndex), label: CustomerLabels.job),
            CustomerDetailField(name: pickerValue(pickerviewModel.pickProduct, at: detail.productIndex), label: CustomerLabels.product),
            CustomerDetailField(name: "\(detail.quantity)", label: CustomerLabels.quantity),
            CustomerDetailField(name: detail.formattedStartDate, label: CustomerLabels.start),
            CustomerDetailField(name: detail.formattedCompletionDate, label: CustomerLabels.complete),
            CustomerDetailField(name: detail.photo, label: CustomerLabels.photo)
        ]
    }

    private var canSendMessages: Bool {
        #if canImport(MessageUI)
        MFMessageComposeViewController.canSendText()
        #else
        false
        #endif
    }

    private var defaultMessageBody: String {
        let firstName = detail.first.trimmingCharacters(in: .whitespacesAndNewlines)
        return firstName.isEmpty
            ? "Hi, following up on your inquiry."
            : "Hi \(firstName), following up on your inquiry."
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    LeadDetailHeaderView(detail: $detail, showFullscreen: $showFullscreen)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    detailFieldList

                    LeadDetailCommentsView(detail: $detail, showPopover: $showPopover)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbarContent }
        .sheet(item: $activeSheet, content: sheetContent)
        .foregroundColor(themeColor)
        .tint(themeColor)
        .background(Color(.systemGroupedBackground))
        .frame(maxWidth: maxWidthForIpad)
    }

    private var detailFieldList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(detailFields.enumerated()), id: \.offset) { index, customer in
                LeadDetailFieldRow(formData: customer)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .overlay(alignment: .bottom) {
                        if index < detailFields.count - 1 {
                            Divider().padding(.leading, 16)
                        }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2))
        )
        .padding(.horizontal)
        .onAppear(perform: syncActiveColor)
        .onChange(of: detail.isActive) { _ in
            syncActiveColor()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: { dismiss() }) {
                Label("Close", systemImage: "xmark.circle")
            }
            .accessibilityLabel("Close")
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                actionMenuButtons
            } label: {
                Label("Action", systemImage: "ellipsis.circle")
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: { activeSheet = .edit }) {
                Text("Edit").fontWeight(.semibold)
            }
            .accessibilityLabel("Edit")
        }
    }

    @ViewBuilder
    private var actionMenuButtons: some View {
        if canSendMessages {
            Button("Send Message") { activeSheet = .message }
        }
        Button("Add to Customer") { }
        Button("Add to Contact") { }
        Button("Add Calendar Event") { }
        Button("$ pay") { }
        Button("Web Page") { }
        Button("Call Phone") { openURL.callPhoneNumber(detail.phone) }
        Button("Send Email") { activeSheet = .email }
        Button("Share My Location") { }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ActiveSheet) -> some View {
        switch sheet {
        case .edit:
            FormUI(
                detail: detail,
                createDate: detail.creationDate,
                startDate: detail.startDate,
                completeDate: detail.completionDate,
                status: "Edit",
                formService: formService
            )
        case .email:
            MailView(
                subject: "Email support",
                message: "Message",
                attachment: nil,
                onResult: { _ in activeSheet = nil }
            )
        case .message:
            messageSheet
        }
    }

    @ViewBuilder
    private var messageSheet: some View {
        #if canImport(MessageUI)
        if MFMessageComposeViewController.canSendText() {
            let recipients = parsedRecipients(from: detail.phone)
            MessageComposeView(recipients: recipients.isEmpty ? nil : recipients, body: defaultMessageBody) { _ in
                activeSheet = nil
            }
        } else {
            unavailableMessageView(text: "Messaging is not available on this device.")
        }
        #else
        unavailableMessageView(text: "Messaging framework not available.")
        #endif
    }

    private func unavailableMessageView(text: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "message")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.headline)
            Button("Close") { activeSheet = nil }
        }
        .padding()
    }

    private func pickerValue(_ values: [String], at index: Int) -> String {
        guard values.indices.contains(index) else { return "" }
        return values[index]
    }

    private func parsedRecipients(from raw: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",; ")
        return raw
            .components(separatedBy: separators)
            .map { $0.filter(\.isNumber) }
            .filter { !$0.isEmpty }
    }

    private func syncActiveColor() {
        activeColor = detail.isActive ? 1 : 0
    }
}

struct LeadDetailUI_Previews: PreviewProvider {
    static var previews: some View {
        LeadDetailUI(detail: CustomerItem(
            id: "8899999",
            isActive: true,
            first: "Peter",
            lastname: "Balsamo",
            street: "5121 Lakefront Blvd Apt D",
            city: "Delray Beach",
            state: "FL",
            zip: "33484",
            amount: 5000,
            creationDate: Date(),
            rate: "5",
            phone: "516-241-4786",
            comments: "Hello",
            spouse: "Janet",
            email: "eunitedws@icloud.com.com",
            contractorIndex: 5,
            photo: "none",
            lastUpdateDate: Date(),
            startDate: Date(),
            completionDate: Date(),
            quantity: 5,
            salesIndex: 1,
            jobIndex: 1,
            productIndex: 1,
            status: "Edit",
            formController: "Customer"
        ))
        .environmentObject(CustomerData())
        .environmentObject(PickerDataModel())
        .preferredColorScheme(.dark)
    }
}
