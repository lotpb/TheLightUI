//
//  WebUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/12/22.
//

import SwiftUI
import SafariServices

struct WebUI: View {
    @State private var selectedBookmark: WebBookmark?
    
    private let bookmarks = WebBookmark.defaultBookmarks
    
    var body: some View {
        NavigationStack {
            List(bookmarks) { bookmark in
                Button {
                    selectedBookmark = bookmark
                } label: {
                    Label(bookmark.title, systemImage: bookmark.systemImage)
                }
            }
            .navigationTitle("Bookmarks")
            .sheet(item: $selectedBookmark) { bookmark in
                SFSafariViewWrapper(url: bookmark.url)
                    .ignoresSafeArea()
            }
        }
    }
}

private struct WebBookmark: Identifiable {
    let id = UUID()
    let title: String
    let url: URL
    let systemImage: String
    
    static let defaultBookmarks: [WebBookmark] = [
        ("Apple", "https://apple.com", "book"),
        ("Google News", "https://news.google.com", "book"),
        ("Bongino Report", "https://bonginoreport.com", "book"),
        ("Blaze", "https://www.theblaze.com", "book"),
        ("Drudge Report", "https://www.drudgereport.com", "book"),
        ("CNN", "https://www.cnn.com", "book")
    ].compactMap { title, urlString, systemImage in
        guard let url = URL(string: urlString) else { return nil }
        return WebBookmark(title: title, url: url, systemImage: systemImage)
    }
}

struct SFSafariViewWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

#Preview("Bookmarks - Dark") {
    WebUI()
        .preferredColorScheme(.dark)
}
