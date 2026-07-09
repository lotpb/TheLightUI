//
//  ExpenseJSONTransfer.swift
//  TheLightUI
//

import SwiftUI
import UniformTypeIdentifiers
import CoreTransferable

/// Identifiable payload for the JSON preview sheet. Presenting with
/// `sheet(item:)` guarantees the sheet is built with the freshly generated
/// text; `sheet(isPresented:)` captured the previous value on first present.
struct ExpenseJSONPreview: Identifiable {
    let id = UUID()
    let text: String
}

/// Shares expense JSON as a .json file. Sharing the raw string would save as
/// plain text, which the import file picker refuses to open.
struct ExpenseJSONFile: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { $0.data }
            .suggestedFileName("Expenses.json")
    }
}

/// Read-only viewer for the exported expense JSON, since Quick Look in the
/// Files app cannot preview .json files.
struct ExpenseJSONPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    let jsonText: String

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(jsonText)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle("Expenses JSON")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(
                        item: ExpenseJSONFile(data: Data(jsonText.utf8)),
                        preview: SharePreview("Expenses.json", image: Image(systemName: "doc.text"))
                    )
                }
            }
        }
    }
}

/// Wraps exported expense JSON for use with `fileExporter`.
struct ExpenseJSONDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.json]

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
