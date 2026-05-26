//
//  WebUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/12/22.
//

import SwiftUI
import SafariServices

// MARK: - Bookmarks
struct WebUI: View {
    @State private var selectedBookmark: WebBookmark?

    private let bookmarks = WebBookmark.defaultBookmarks

    var body: some View {
        NavigationStack {
            bookmarkList
                .navigationTitle("Bookmarks")
                .sheet(item: $selectedBookmark) { bookmark in
                    safariView(for: bookmark)
                }
                .padding(.top, 30)
        }
    }

    private var bookmarkList: some View {
        List(bookmarks) { bookmark in
            bookmarkRow(bookmark)
        }
    }

    private func bookmarkRow(_ bookmark: WebBookmark) -> some View {
        Button {
            selectedBookmark = bookmark
        } label: {
            Label(bookmark.title, systemImage: bookmark.systemImage)
        }
    }

    private func safariView(for bookmark: WebBookmark) -> some View {
        SFSafariViewWrapper(url: bookmark.url)
            .ignoresSafeArea()
    }
}

// MARK: - Model
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

// MARK: - Safari Wrapper
struct SFSafariViewWrapper: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

// MARK: - Preview
#Preview("Bookmarks - Dark") {
    WebUI()
        .preferredColorScheme(.dark)
}
