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

    @AppStorage(SettingsUI.firstNameKey) private var first = ""
    @AppStorage(SettingsUI.lastNameKey) private var last = ""
    @AppStorage(SettingsUI.emailKey) private var emailAddress = ""

    @State private var qrCode = UIImage()
    @State private var isShowingScanner = false
    @StateObject private var prospects = Prospects()

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    private var membershipPayload: String {
        "\(first) \(last)\n\(emailAddress)"
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Membership")
                .toolbar { toolbarContent }
                .sheet(isPresented: $isShowingScanner) {
                    scannerView
                }
                .onAppear(perform: updateCode)
                .onChange(of: first) { _ in updateCode() }
                .onChange(of: last) { _ in updateCode() }
                .onChange(of: emailAddress) { _ in updateCode() }
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
            TextField("Last Name", text: $last)
                .textFieldStyle(.roundedBorder)
                .textContentType(.familyName)
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
        let imageSaver = ImageSaver()
        imageSaver.writeToPhotoAlbum(image: qrCode)
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

        let person = Prospect()
        person.name = details[0]
        person.email = details[1]
        prospects.add(person)
    }
}

// MARK: - Preview
#Preview("Membership - Dark") {
    MembershipUI()
        .preferredColorScheme(.dark)
}
