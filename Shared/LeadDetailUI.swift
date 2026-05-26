//
//  LeadDetailUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

import SwiftUI

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
    @State private var showFullscreen: Bool = false
    @State private var showActionSheet: Bool = false
    @State private var showPopover = false
    
    @State private var activeSheet: ActiveSheet?

    private enum ActiveSheet: Identifiable {
        case edit
        case email

        var id: String {
            switch self {
            case .edit: return "edit"
            case .email: return "email"
            }
        }
    }
    
    private var themeColor: Color { (color == 0) ? .purple : .orange }
    
    var body: some View {
        
        let saleNo = Int(detail.salesNo) ?? 0
        let jobNo = Int(detail.jobNo) ?? 0
        let prodNo = Int(detail.prodNo) ?? 0
        let contractNo = Int(detail.contractor) ?? 0
        
        let dataArray = [
            ListModel(name: detail.first, label: detail.l11),
            ListModel(name: detail.phone, label: detail.l12),
            ListModel(name: pickerValue(pickerviewModel.pickContractor, at: contractNo), label: detail.l13),
            ListModel(name: detail.spouse, label: detail.l14),
            ListModel(name: detail.email, label: detail.l15),
            ListModel(name: detail.last, label: detail.l16),
            ListModel(name: detail.rate, label: detail.l21),
            ListModel(name: pickerValue(pickerviewModel.pickSalesman, at: saleNo), label: detail.l22),
            ListModel(name: pickerValue(pickerviewModel.pickJob, at: jobNo), label: detail.l23),
            ListModel(name: pickerValue(pickerviewModel.pickProduct, at: prodNo), label: detail.l24),
            ListModel(name: "\(detail.quan)", label: detail.l25),
            ListModel(name: detail.start, label: detail.l26),
            ListModel(name: detail.complete, label: detail.l27),
            ListModel(name: detail.photo, label: detail.l17)
        ]
        
        ZStack {
            // Subtle system background that adapts to appearance
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 16) {
                    TopViewUI(detail: $detail, showFullscreen: $showFullscreen)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Card-style list of fields
                    LazyVStack(spacing: 0) {
                        ForEach(Array(dataArray.enumerated()), id: \.offset) { index, customer in
                            CenterViewUI(formData: customer)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .overlay(
                                    index < dataArray.count - 1 ? Divider().padding(.leading, 16) : nil
                                )
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(.separator).opacity(0.2))
                    )
                    .padding(.horizontal)
                    .onAppear {
                        self.activeColor = (self.detail.active == "1") ? 1 : 0
                    }
                    .onChange(of: detail.active) { newValue in
                        self.activeColor = (newValue == "1") ? 1 : 0
                    }

                    BottomViewUI(detail: $detail, showPopover: $showPopover)
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Label("Close", systemImage: "xmark.circle")
                }
                .accessibilityLabel("Close")
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Send Message") {}
                    Button("Add to Customer") {}
                    Button("Add to Contact") {}
                    Button("Add Calendar Event") {}
                    Button("$ pay") {}
                    Button("Web Page") {}
                    Button("Call Phone") { callPhoneNumber(detail.phone) }
                    Button("Send Email") { activeSheet = .email }
                    Button("Share My Location") {}
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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                editForm()
            case .email:
                mailSheet()
            }
        }
        .foregroundColor(themeColor)
        .tint(themeColor)
        .background(Color(.systemGroupedBackground))
        .frame(maxWidth: maxWidthForIpad)
    }
    
    private func pickerValue(_ values: [String], at index: Int) -> String {
        guard values.indices.contains(index) else { return "" }
        return values[index]
    }
    

    private func callPhoneNumber(_ raw: String) {
        let digits = raw.filter { $0.isNumber }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
        #if targetEnvironment(simulator)
        // Prevent simulator crash/unsupported behavior by just printing
        print("Dialing: \(digits)")
        #else
        UIApplication.shared.open(url)
        #endif
    }
    
    @ViewBuilder
    private func editForm() -> some View {
        FormUI(
            detail: customerItem(
                id: detail.id,
                active: detail.active,
                first: detail.first,
                lastname: detail.lastname,
                address: detail.address,
                street: detail.street,
                city: detail.city,
                state: detail.state,
                zip: detail.zip,
                amount: detail.amount,
                date: detail.date,
                rate: detail.rate,
                phone: detail.phone,
                comments: detail.comments,
                spouse: detail.spouse,
                email: detail.email,
                contractor: detail.contractor,
                photo: detail.photo,
                last: detail.last,
                start: detail.start,
                complete: detail.complete,
                quan: detail.quan,
                salesNo: detail.salesNo,
                jobNo: detail.jobNo,
                prodNo: detail.prodNo,
                l11: "",
                l12: "",
                l13: "",
                l14: "",
                l15: "",
                l16: "",
                l17: "",
                l21: "",
                l22: "",
                l23: "",
                l24: "",
                l25: "",
                l26: "",
                l27: "",
                l1datetext: "Sale Date:",
                lnewsTitle: "",
                status: detail.status,
                formController: detail.formController
            ),
            createDate: Date(),
            startDate: Date(),
            completeDate: Date(),
            status: "Edit"
        )
    }

    @ViewBuilder
    private func mailSheet() -> some View {
        MailView(
            subject: "Email support",
            message: "Message",
            attachment: nil,
            onResult: { _ in activeSheet = nil }
        )
    }
}

struct TopViewUI: View {
    
    @AppStorage("color") var color: Int?
    @AppStorage("activeColor") var activeColor: Int?
    
    @Binding var detail: customerItem
    @Binding var showFullscreen: Bool
    
    private func formattedAmount(_ raw: String) -> String {
        if raw.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("$") {
            return raw
        } else {
            return "$" + raw
        }
    }
   
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.lastname)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(detail.street)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(detail.address)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(spacing: 8) {
                    Image("taylor_swift_profile")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1))
                        .shadow(radius: 2)

                    Text(detail.id)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }

            HStack(alignment: .center, spacing: 12) {
                Label(detail.active == "1" ? "Following" : "Follow", systemImage: detail.active == "1" ? "star.fill" : "star")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(detail.active == "1" ? .blue : .secondary)
                    .onTapGesture { toggleActive() }
                    .accessibilityLabel("Toggle Follow")

                Spacer()

                Button {
                    showFullscreen.toggle()
                } label: {
                    Label("Map", systemImage: "map")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .controlSize(.mini)
                //.accessibilityLabel("Show Map")
            }

            Divider()

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedAmount(detail.amount))
                        .font(.title2).fontWeight(.semibold)
                        .lineLimit(1)
                    Text(detail.l1datetext)
                        .font(.caption).foregroundStyle(.secondary)
                    Text(detail.date)
                        .font(.headline)
                }
                Spacer()
                if detail.rate == "5" {
                    Text("Priority")
                        .font(.subheadline.weight(.semibold))
                        //.font(.footnote.weight(.semibold))
                        .padding(.horizontal, 13)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.9), in: Capsule())
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2))
        )
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .fullScreenCover(isPresented: $showFullscreen, content: {
            MapUI(mapstreet: detail.street, mapcity: detail.city, mapstate: detail.state, mapzip: detail.zip, travelTime: 0.00, distance: 0.00)
        })
    }
    
    private func toggleActive() {
        detail.active = detail.active == "1" ? "0" : "1"
        activeColor = detail.active == "1" ? 1 : 0
    }
}

struct CenterViewUI : View {
    
    var formData: ListModel
    @AppStorage("color") var color: Int?
    
    var body: some View {
        HStack(spacing: 12) {
            Text(formData.label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.secondary)
            Spacer()
            Text(formData.name)
                .font(.body)
                .foregroundStyle(Color.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

struct BottomViewUI: View {
    @AppStorage("color") var color: Int?
    @Binding var detail: customerItem
    @Binding var showPopover: Bool
    
    private var accentColor: Color {
        color == 0 ? Color.purple : Color.orange
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "text.bubble")
                Text("Comments")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button("Read more") { showPopover = true }
                    .buttonStyle(.bordered)
                    .tint(accentColor)
            }
            .foregroundStyle(accentColor)

            Text(detail.lnewsTitle)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .font(.footnote)

            Text(detail.comments)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.2))
        )
        .popover(isPresented: $showPopover) {
            PopoverContent(detail: $detail)
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
        .frame(width: 380, height: 260)
    }
}

struct LeadDetailUI_Previews: PreviewProvider {
    static var previews: some View {

            LeadDetailUI(detail: customerItem(
                id: "8899999", active: "1", first: "Peter", lastname: "Balsamo", address: "Massapequa Ny 11758", street: "1142 Hicksville Road", city: "", state: "", zip: "", amount: "$5000.00", date:"Mar 30 2021", rate: "5", phone: "516-241-4786", comments: "Hello", spouse: "Janet", email: "email.com", contractor: "Jose", photo: "none", last: "Mar 12 1989", start: "Mar 7 2090", complete: "Nov 23 1958", quan: "5", salesNo: "", jobNo: "", prodNo: "", l11: "First", l12: "Phone", l13: "Contractor", l14: "Spouse", l15: "Email", l16: "Last Updated", l17: "Photo", l21: "Rating", l22: "Salesman", l23: "Job", l24: "Product", l25: "Quan", l26: "Start", l27: "Completion", l1datetext: "Sale Date:", lnewsTitle: "Comment News:", status: "Edit", formController: "Customer"
            ))
            .environmentObject(CustomerData())
            .environmentObject(PickerDataModel())
            .preferredColorScheme(.dark)
       }
}
