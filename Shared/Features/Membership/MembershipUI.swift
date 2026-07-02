//
//  MembershipUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/27/21.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import CodeScanner

// MARK: - Membership
struct MembershipUI: View {
    private enum Layout {
        static let contentSpacing: CGFloat = 16
        static let qrCodeSize: CGFloat = 190
    }

    @State private var first = ""
    @State private var last = ""
    @State private var emailAddress = ""
    @State private var fullName = ""
    @State private var qrCode = UIImage()
    @State private var isShowingScanner = false

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    private var membershipPayload: String {
        "\(first) \(last)\n\(emailAddress)"
    }

    private var storedFullName: String {
        [first, last]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " ")
    }

    var body: some View {
        NavigationStack {
            content
                .background(Color(.systemGroupedBackground))
                .scrollDismissesKeyboard(.interactively)
                .navigationTitle("Membership")
                .toolbar { toolbarContent }
                .sheet(isPresented: $isShowingScanner) {
                    scannerView
                }
                .onAppear {
                    loadSecureSettings()
                    syncFullNameFromStorage()
                }
                .onChange(of: fullName) {
                    updateNameStorage(from: fullName)
                }
                .onChange(of: first) {
                    SecureSettingsStore.saveString(first, forKey: SettingsUI.firstNameKey)
                }
                .onChange(of: last) {
                    SecureSettingsStore.saveString(last, forKey: SettingsUI.lastNameKey)
                }
                .onChange(of: emailAddress) {
                    SecureSettingsStore.saveString(emailAddress, forKey: SettingsUI.emailKey)
                }
                .onChange(of: membershipPayload) {
                    updateCode()
                }
        }
    }

    // MARK: - Content

    private var content: some View {
        ScrollView {
            VStack(spacing: Layout.contentSpacing) {
                memberFields
                membershipCard
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
    }

    private var memberFields: some View {
        VStack(spacing: 10) {
            fieldCard(label: "name") {
                TextField("First and Last Name", text: $fullName)
                    .textContentType(.name)
                    .submitLabel(.next)
            }

            fieldCard(label: "email") {
                TextField("Email Address", text: $emailAddress)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
            }
        }
    }

    // A Contacts-style field card: small secondary label above the input.
    private func fieldCard(label: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var cardDisplayName: String {
        let name = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Member Name" : name
    }

    // A Wallet-pass-style card holding the QR code and member details.
    private var membershipCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TheLight")
                        .font(.headline)

                    Text("Member")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
            }

            // QR codes need a light background to stay scannable in dark mode.
            Image(uiImage: qrCode)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: Layout.qrCodeSize, height: Layout.qrCodeSize)
                .padding(10)
                .background(.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .contextMenu {
                    Button(action: saveQRCode) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                }
                .accessibilityLabel("Membership QR code")

            VStack(spacing: 2) {
                Text(cardDisplayName)
                    .font(.subheadline.weight(.semibold))

                if !emailAddress.isEmpty {
                    Text(emailAddress)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                isShowingScanner = true
            } label: {
                Label("Scan", systemImage: "barcode.viewfinder")
            }
        }
    }

    private var scannerView: some View {
        CodeScannerView(
            codeTypes: [.qr],
            simulatedData: simulatedScanData,
            completion: handleScan
        )
    }

    private var simulatedScanData: String {
        let names = ["Maxim", "Oleg", "Vera", "Andrei", "Anot", "Yan"]
        let lastNames = ["Vainikka", "Belii", "CHernii", "Xahori"]
        let name = names.randomElement() ?? "Maxim"
        let lastName = lastNames.randomElement() ?? "Vainikka"
        return "\(name) \(lastName)\nvainikkaxd@gmail.com"
    }

    // MARK: - Actions

    private func saveQRCode() {
        Task {
            try? await ImageSaver().writeToPhotoAlbum(image: qrCode)
        }
    }

    private func loadSecureSettings() {
        first = SecureSettingsStore.loadString(forKey: SettingsUI.firstNameKey)
        last = SecureSettingsStore.loadString(forKey: SettingsUI.lastNameKey)
        emailAddress = SecureSettingsStore.loadString(forKey: SettingsUI.emailKey)
    }

    private func syncFullNameFromStorage() {
        fullName = storedFullName
        updateCode()
    }

    private func updateNameStorage(from fullName: String) {
        let nameParts = fullName.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        first = nameParts.first.map(String.init) ?? ""
        last = nameParts.dropFirst().first.map(String.init) ?? ""
    }

    private func updateCode() {
        qrCode = generateQRCode(from: membershipPayload)
    }

    private func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        guard let outputImage = filter.outputImage,
              let cgImage = context.createCGImage(outputImage, from: outputImage.extent) else {
            return UIImage(systemName: "xmark.circle") ?? UIImage()
        }

        return UIImage(cgImage: cgImage)
    }

    private func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false

        switch result {
        case .success(let result):
            addProspect(from: result.string)
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }

    private func addProspect(from scannedValue: String) {
        let details = scannedValue.components(separatedBy: "\n")
        guard details.count == 2 else { return }

        fullName = details[0]
        emailAddress = details[1]
    }
}

// MARK: - Preview
#Preview("Membership - Dark") {
    MembershipUI()
        .preferredColorScheme(.dark)
}
