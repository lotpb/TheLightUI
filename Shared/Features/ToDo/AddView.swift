//
//  AddView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI

struct AddView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(ListViewModel.self) private var listViewModel
    @State private var textFieldText = ""
    @State private var notesText = ""
    @State private var alertTitle = ""
    @State private var showAlert = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("New Item")
                        .font(.headline)
                    TextField("Title…", text: $textFieldText)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .submitLabel(.next)
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    TextField("Notes (optional)", text: $notesText, axis: .vertical)
                        .lineLimit(2...8)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onSubmit { saveButtonClicked() }
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.15))
                )
                .padding(.horizontal)
                
                Button(action: saveButtonClicked) {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(textFieldText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationTitle("Add an Item ✎")
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func saveButtonClicked() {
        if textIsAppropriate() {
            listViewModel.addItem(title: textFieldText, notes: notesText)
            dismiss()
        }
    }
    
    private func textIsAppropriate() -> Bool {
        let trimmed = textFieldText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < 3 {
            alertTitle = "Need at least 3 characters🔒"
            showAlert = true
            return false
        }
        return true
    }
}

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ListViewModel.self) private var listViewModel

    let item: ItemModel
    @State private var titleText: String
    @State private var notesText: String

    init(item: ItemModel) {
        self.item = item
        _titleText = State(initialValue: item.title)
        _notesText = State(initialValue: item.notes)
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Edit Item")
                        .font(.headline)
                    TextField("Title…", text: $titleText)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .submitLabel(.next)
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    TextField("Notes (optional)", text: $notesText, axis: .vertical)
                        .lineLimit(2...8)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onSubmit { save() }
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(16)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.15))
                )
                .padding(.horizontal)

                Button(action: save) {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(titleText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Edit Item")
    }

    private func save() {
        let trimmed = titleText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 3 else { return }
        listViewModel.updateItemContent(item, title: trimmed, notes: notesText)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AddView()
    }
    .environment(ListViewModel(itemStore: UserDefaultsItemStore()))
}
