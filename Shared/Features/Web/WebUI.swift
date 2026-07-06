//
//  WebUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/12/22.
//

import SwiftUI
import WebKit

// MARK: - Bookmarks
struct WebUI: View {
    /// Called when a bookmark's web page opens, so the iPad root layout can
    /// collapse its sidebar and give the page the full width.
    var onOpenPage: (() -> Void)? = nil

    private let bookmarks = WebBookmark.defaultBookmarks

    // A plain stack rather than a split view: WebUI sits inside the root
    // sidebar's detail column on iPad, where nested split views render oddly.
    var body: some View {
        NavigationStack {
            List(bookmarks) { bookmark in
                NavigationLink(value: bookmark) {
                    BookmarkRow(bookmark: bookmark)
                }
            }
            .navigationTitle("Bookmarks")
            .navigationDestination(for: WebBookmark.self) { bookmark in
                WebBookmarkDetail(bookmark: bookmark)
                    .onAppear { onOpenPage?() }
            }
        }
    }
}

// MARK: - Views
private struct BookmarkRow: View {
    let bookmark: WebBookmark

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(bookmark.title)
                    .font(.headline)

                Text(bookmark.host)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: bookmark.systemImage)
                .foregroundStyle(Color.accentColor)
        }
        .padding(.vertical, 2)
    }
}

private struct WebBookmarkDetail: View {
    let bookmark: WebBookmark

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                WebView(url: bookmark.url)
                    .webViewBackForwardNavigationGestures(.enabled)
                    .webViewMagnificationGestures(.enabled)
                    .webViewTextSelection(.enabled)
                    .webViewLinkPreviews(.enabled)
            } else {
                LegacyWebView(url: bookmark.url)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .navigationTitle(bookmark.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: bookmark.url)
            }
        }
    }
}

/// Renders web content on the project's iOS 16 deployment floor, where the SwiftUI
/// `WebView` (iOS 26+) isn't available, by bridging a `WKWebView`.
private struct LegacyWebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.allowsBackForwardNavigationGestures = true
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard webView.url != url else { return }
        webView.load(URLRequest(url: url))
    }
}

// MARK: - Model
private struct WebBookmark: Identifiable, Hashable {
    let title: String
    let url: URL
    let systemImage: String

    var id: URL { url }

    var host: String {
        url.host(percentEncoded: false) ?? url.absoluteString
    }

    static let defaultBookmarks: [WebBookmark] = [
        ("Apple", "https://apple.com", "apple.logo"),
        ("Google News", "https://news.google.com", "newspaper"),
        ("Bongino Report", "https://bonginoreport.com", "newspaper"),
        ("Blaze", "https://www.theblaze.com", "newspaper"),
        ("Drudge Report", "https://www.drudgereport.com", "newspaper"),
        ("CNN", "https://www.cnn.com", "newspaper")
    ].compactMap { title, urlString, systemImage in
        guard let url = URL(string: urlString) else { return nil }
        return WebBookmark(title: title, url: url, systemImage: systemImage)
    }
}

// MARK: - Preview
#Preview("Bookmarks - Dark") {
    WebUI()
        .preferredColorScheme(.dark)
}
