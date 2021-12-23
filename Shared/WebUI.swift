//
//  WebUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/12/22.
//

import SwiftUI
import SafariServices


struct WebUI: View {
    @State private var showCNN: Bool = false
    @State private var showDrudge: Bool = false
    @State private var showBongino: Bool = false
    @State private var showBlaze: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Label("Bongino Report", systemImage: "book")
                    .onTapGesture {
                        showBongino.toggle()
                    }
                    .fullScreenCover(isPresented: $showBongino, content: {
                        SFSafariViewWrapper(url: URL(string: "https://bonginoreport.com")!)
                    })
                
                Label("Blaze", systemImage: "book")
                    .onTapGesture {
                        showBlaze.toggle()
                    }
                    .fullScreenCover(isPresented: $showBlaze, content: {
                        SFSafariViewWrapper(url: URL(string: "https://www.theblaze.com")!)
                    })
                
                Label("Drudge Report", systemImage: "book")
                    .onTapGesture {
                        showDrudge.toggle()
                    }
                    .fullScreenCover(isPresented: $showDrudge, content: {
                        SFSafariViewWrapper(url: URL(string: "https://www.drudgereport.com")!)
                    })
                
                Label("CNN", systemImage: "book")
                    .onTapGesture {
                        showCNN.toggle()
                    }
                    .fullScreenCover(isPresented: $showCNN, content: {
                        SFSafariViewWrapper(url: URL(string: "https://www.cnn.com")!)
                    })
            }
            .onAppear {
                withAnimation(.spring()) {
                    showCNN.toggle()
                }
            }
            .navigationTitle("Bookmarks")
        }
    }
}


struct SFSafariViewWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: UIViewControllerRepresentableContext<Self>) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SFSafariViewWrapper>) {
        return
    }
}

struct WebUI_Previews: PreviewProvider {
    static var previews: some View {
        WebUI().preferredColorScheme(.dark)
    }
}
