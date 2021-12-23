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
        
        NavigationView {
            VStack {
                TextField(last, text: $last).textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.none)
                    .font(.headline)
                    .padding(.top, 15)
                
                TextField(emailAddress, text: $emailAddress).textFieldStyle(RoundedBorderTextFieldStyle())
                    .textContentType(.none)
                    .font(.headline)
                
                Image(uiImage: qrCode)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width:200, height: 200)
                    .contextMenu {
                        Button {
                            let imageSaver = ImageSaver()
                            imageSaver.writeToPhotoAlbum(image: qrCode)
                        } label: {
                            Label("Save to Photo's", systemImage: "square.and.arrow.down")
                        }
                    }
                    .padding(.top, 15)
                
                Spacer()
            }
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
            .onChange(of: last) { _ in updateCode() }
            .onChange(of: emailAddress) { _ in updateCode() }
        }
    }
    
    func updateCode() {
        qrCode = generateQRCode(from: "\(last)\n\(emailAddress)")
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

struct MembershipUI_Previews: PreviewProvider {
    static var previews: some View {
        MembershipUI()
            .preferredColorScheme(.dark)
    }
}
