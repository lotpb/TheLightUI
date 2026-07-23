//
//  WebUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/12/22.
//

import SwiftUI
import WebKit

// MARK: - Model
struct WebBookmark: Identifiable, Hashable, Codable {
    var id: UUID
    let title: String
    let url: URL
    let systemImage: String

    var host: String {
        url.host(percentEncoded: false) ?? url.absoluteString
    }

    init(id: UUID = UUID(), title: String, url: URL, systemImage: String = "globe") {
        self.id = id
        self.title = title
        self.url = url
        self.systemImage = systemImage
    }
}

// MARK: - Store
@Observable
final class BookmarkStore {
    private static let defaultsKey = "web.bookmarks"

    var bookmarks: [WebBookmark]

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([WebBookmark].self, from: data) {
            bookmarks = saved
        } else {
            bookmarks = Self.defaultBookmarks
        }
    }

    func add(_ bookmark: WebBookmark) {
        bookmarks.append(bookmark)
        persist()
    }

    func delete(at offsets: IndexSet) {
        bookmarks.remove(atOffsets: offsets)
        persist()
    }

    func delete(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(bookmarks) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    private static let defaultBookmarks: [WebBookmark] = [
        ("Apple",         "https://apple.com",               "apple.logo"),
        ("Google News",   "https://news.google.com",         "newspaper"),
        ("Bongino Report","https://bonginoreport.com",        "newspaper"),
        ("Blaze",         "https://www.theblaze.com",        "newspaper"),
        ("Drudge Report", "https://www.drudgereport.com",    "newspaper"),
        ("CNN",           "https://www.cnn.com",             "newspaper"),
    ].compactMap { title, urlString, icon in
        guard let url = URL(string: urlString) else { return nil }
        return WebBookmark(title: title, url: url, systemImage: icon)
    }
}

// MARK: - WebUI
struct WebUI: View {
    /// Called when a bookmark's web page opens, so the iPad root layout can
    /// collapse its sidebar and give the page the full width.
    var onOpenPage: (() -> Void)? = nil

    @State private var store = BookmarkStore()
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.bookmarks) { bookmark in
                    NavigationLink(value: bookmark) {
                        BookmarkRow(bookmark: bookmark)
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            store.delete(id: bookmark.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
                .onDelete { offsets in
                    store.delete(at: offsets)
                }

                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add Bookmark", systemImage: "plus")
                }
            }
            .navigationTitle("Bookmarks")
            .navigationDestination(for: WebBookmark.self) { bookmark in
                WebBookmarkDetail(bookmark: bookmark, store: store)
                    .onAppear { onOpenPage?() }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddBookmarkSheet { bookmark in
                    store.add(bookmark)
                }
            }
        }
    }
}

// MARK: - Add Bookmark Sheet
private struct AddBookmarkSheet: View {
    let onAdd: (WebBookmark) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var urlText = ""
    @State private var showingURLError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Bookmark") {
                    TextField("Title", text: $title)
                    TextField("URL (e.g. https://example.com)", text: $urlText)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
            }
            .navigationTitle("Add Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add") { addBookmark() }
                        .disabled(title.isEmpty || urlText.isEmpty)
                }
            }
            .alert("Invalid URL", isPresented: $showingURLError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Enter a valid web address such as https://example.com")
            }
        }
    }

    private func addBookmark() {
        var raw = urlText.trimmingCharacters(in: .whitespaces)
        if !raw.lowercased().hasPrefix("http") { raw = "https://\(raw)" }
        guard let url = URL(string: raw), url.host != nil else {
            showingURLError = true
            return
        }
        onAdd(WebBookmark(title: title.trimmingCharacters(in: .whitespaces), url: url))
        dismiss()
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
    let store: BookmarkStore

    @Environment(\.dismiss) private var dismiss

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
                Menu {
                    ShareLink(item: bookmark.url)
                    Divider()
                    Button(role: .destructive) {
                        store.delete(id: bookmark.id)
                        dismiss()
                    } label: {
                        Label("Remove Bookmark", systemImage: "bookmark.slash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
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

// MARK: - Preview
#Preview("Bookmarks - Dark") {
    WebUI()
        .preferredColorScheme(.dark)
}
