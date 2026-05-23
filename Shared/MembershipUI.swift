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

struct MembershipUI: View {
    @AppStorage(SettingsUI.firstNameKey) var first: String = ""
    @AppStorage(SettingsUI.lastNameKey) var last: String = ""
    @AppStorage(SettingsUI.emailKey) var emailAddress: String = ""
    
    @State private var qrCode = UIImage()
    @State private var isShowingScanner = false
    //@EnvironmentObject var prospects: Prospects
    @StateObject var prospects = Prospects()
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    
    var body: some View {
        
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Last Name", text: $last)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.familyName)
                    .font(.headline)
                    .padding(.top, 15)
                
                TextField("Email Address", text: $emailAddress)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .font(.headline)
                
                Image(uiImage: qrCode)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 220, height: 220)
                    .contextMenu {
                        Button {
                            let imageSaver = ImageSaver()
                            imageSaver.writeToPhotoAlbum(image: qrCode)
                        } label: {
                            Label("Save to Photos", systemImage: "square.and.arrow.down")
                        }
                    }
                    .padding(.top, 15)
                
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Membership")
            .toolbar {
                Button {
                    isShowingScanner = true
                } label: {
                    Label("Scan", systemImage: "barcode.viewfinder")
                }
            }
            .sheet(isPresented: $isShowingScanner) {
                let names = ["Maxim", "Oleg", "Vera", "Andrei", "Anot", "Yan"]
                let lastNames = ["Vainikka", "Belii", "CHernii", "Xahori"]
                let name = names.randomElement()!
                let lastName = lastNames.randomElement()!
                CodeScannerView(codeTypes: [.qr], simulatedData: "\(name) \(lastName)\nvainikkaxd@gmail.com", completion: handleScan)
            }
            .onAppear(perform: updateCode)
            .onChange(of: first) { _ in updateCode() }
            .onChange(of: last) { _ in updateCode() }
            .onChange(of: emailAddress) { _ in updateCode() }
        }
    }
    
    private var membershipPayload: String {
        "\(first) \(last)\n\(emailAddress)"
    }
    
    func updateCode() {
        qrCode = generateQRCode(from: membershipPayload)
    }
    
    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
        
        switch result {
        case .success(let result):
            let details = result.string.components(separatedBy: "\n")
            guard details.count == 2 else { return }
            
            let person = Prospect()
            person.name = details[0]
            person.email = details[1]
            prospects.add(person)
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
        }
    }
}

#Preview("Membership - Dark") {
    MembershipUI()
        .preferredColorScheme(.dark)
}
