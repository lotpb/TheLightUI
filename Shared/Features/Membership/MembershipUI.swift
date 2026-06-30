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
        static let qrCodeSize: CGFloat = 220
        static let topPadding: CGFloat = 15
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
            
                //.onChange(of: fullName) { newValue in updateNameStorage(from: newValue) }
            
                .onChange(of: first) {
                    SecureSettingsStore.saveString(first, forKey: SettingsUI.firstNameKey)
                    updateCode()
                }
//                .onChange(of: first) { newValue in
//                    SecureSettingsStore.saveString(newValue, forKey: SettingsUI.firstNameKey)
//                    updateCode()
//                }
                .onChange(of: last) {
                    SecureSettingsStore.saveString(last, forKey: SettingsUI.lastNameKey)
                    updateCode()
                }
//                .onChange(of: last) { newValue in
//                    SecureSettingsStore.saveString(newValue, forKey: SettingsUI.lastNameKey)
//                    updateCode()
//                }
                .onChange(of: emailAddress) {
                    SecureSettingsStore.saveString(emailAddress, forKey: SettingsUI.emailKey)
                    updateCode()
                }
//                .onChange(of: ) { newValue in
//                    SecureSettingsStore.saveString(newValue, forKey: SettingsUI.emailKey)
//                    updateCode()
//                }
        }
    }

    // MARK: - Content

    private var content: some View {
        VStack(spacing: Layout.contentSpacing) {
            memberFields
            qrCodeImage
            Spacer()
        }
        .padding(.horizontal)
    }

    private var memberFields: some View {
        Group {
            TextField("First and Last Name", text: $fullName)
                .textFieldStyle(.roundedBorder)
                .textContentType(.name)
                .font(.headline)
                .padding(.top, Layout.topPadding)

            TextField("Email Address", text: $emailAddress)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .font(.headline)
        }
    }

    private var qrCodeImage: some View {
        Image(uiImage: qrCode)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(width: Layout.qrCodeSize, height: Layout.qrCodeSize)
            .contextMenu {
                Button(action: saveQRCode) {
                    Label("Save to Photos", systemImage: "square.and.arrow.down")
                }
            }
            .padding(.top, Layout.topPadding)
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
