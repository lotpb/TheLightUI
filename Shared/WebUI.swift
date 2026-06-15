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
    @State private var selectedBookmark: WebBookmark? = WebBookmark.defaultBookmarks.first

    private let bookmarks = WebBookmark.defaultBookmarks

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width > 700 {
                HStack(spacing: 0) {
                    bookmarkList
                        .frame(width: 280)

                    Divider()

                    detailView
                }
            } else {
                VStack(spacing: 0) {
                    bookmarkPicker
                    Divider()
                    detailView
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var bookmarkList: some View {
        List(bookmarks) { bookmark in
            Button {
                selectedBookmark = bookmark
            } label: {
                BookmarkRow(
                    bookmark: bookmark,
                    isSelected: selectedBookmark == bookmark
                )
            }
            .buttonStyle(.plain)
        }
        .listStyle(.sidebar)
    }

    private var bookmarkPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(bookmarks) { bookmark in
                    Button {
                        selectedBookmark = bookmark
                    } label: {
                        Label(bookmark.title, systemImage: bookmark.systemImage)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedBookmark == bookmark ? Color.accentColor : Color.secondary.opacity(0.12))
                            )
                            .foregroundStyle(selectedBookmark == bookmark ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        if let selectedBookmark {
            WebBookmarkDetail(bookmark: selectedBookmark)
        } else {
            PlaceholderView(
                title: "Select a Bookmark",
                message: "Choose a website from the bookmarks list.",
                systemImage: "bookmark"
            )
        }
    }
}

// MARK: - Views
private struct BookmarkRow: View {
    let bookmark: WebBookmark
    let isSelected: Bool

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(bookmark.title)
                    .font(.headline)

                Text(bookmark.host)
                    .font(.subheadline)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
            }
        } icon: {
            Image(systemName: bookmark.systemImage)
                .foregroundStyle(isSelected ? Color.white : Color.accentColor)
        }
        .padding(.vertical, 4)
        .foregroundStyle(isSelected ? .white : .primary)
        .listRowBackground(isSelected ? Color.accentColor : Color.clear)
    }
}

private struct WebBookmarkDetail: View {
    let bookmark: WebBookmark

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                WebView(url: bookmark.url)
                    .webViewBackForwardNavigationGestures(.enabled)
            } else {
                fallbackView
            }
        }
    }

    private var fallbackView: some View {
        VStack(spacing: 20) {
            PlaceholderView(
                title: "Web Preview Unavailable",
                message: "Open this bookmark in Safari to view the page.",
                systemImage: "safari"
            )

            Link("Open in Safari", destination: bookmark.url)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

private struct PlaceholderView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title3.weight(.semibold))

            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Model
private struct WebBookmark: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let url: URL
    let systemImage: String

    var host: String {
        url.host(percentEncoded: false) ?? url.absoluteString
    }

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

// MARK: - Preview
#Preview("Bookmarks - Dark") {
    WebUI()
        .preferredColorScheme(.dark)
}
