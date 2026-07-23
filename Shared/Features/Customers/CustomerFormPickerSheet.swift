//
//  CustomerFormPickerSheet.swift
//  TheLightUI
//

import SwiftUI

// Which editable picker list to manage; used as sheet(item:) identity.
enum PickerType: String, Identifiable {
    case salesman, job, product, advertiser, contractor
    var id: String { rawValue }
}

// MARK: - Picker Management Sheet
// Lets the user add and delete items from one of the editable picker lists.

struct PickerManagementSheet: View {
    let pickerType: PickerType
    let model: PickerDataModel

    @Environment(\.dismiss) private var dismiss
    @State private var newItem = ""

    private var title: String {
        switch pickerType {
        case .salesman:   "Salesmen"
        case .job:        "Jobs"
        case .product:    "Products"
        case .advertiser: "Advertisers"
        case .contractor: "Contractors"
        }
    }

    // Items to display — excludes the empty "None" placeholder at index 0.
    private var displayItems: [String] {
        switch pickerType {
        case .salesman:   Array(model.pickSalesman.dropFirst())
        case .job:        Array(model.pickJob.dropFirst())
        case .product:    Array(model.pickProduct.dropFirst())
        case .advertiser: Array(model.pickAdvertiser.dropFirst())
        case .contractor: Array(model.pickContractor.dropFirst())
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(displayItems.indices, id: \.self) { i in
                    Text(displayItems[i])
                        .foregroundStyle(Color.primary)
                }
                .onDelete { offsets in
                    // Shift by 1 to skip the protected empty "None" entry at index 0.
                    let shifted = IndexSet(offsets.map { $0 + 1 })
                    switch pickerType {
                    case .salesman:   model.deleteSalesman(at: shifted)
                    case .job:        model.deleteJob(at: shifted)
                    case .product:    model.deleteProduct(at: shifted)
                    case .advertiser: model.deleteAdvertiser(at: shifted)
                    case .contractor: model.deleteContractor(at: shifted)
                    }
                }

                HStack {
                    TextField("New item", text: $newItem)
                        .onSubmit(addItem)
                    Button("Add", action: addItem)
                        .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        switch pickerType {
        case .salesman:   model.addSalesman(trimmed)
        case .job:        model.addJob(trimmed)
        case .product:    model.addProduct(trimmed)
        case .advertiser: model.addAdvertiser(trimmed)
        case .contractor: model.addContractor(trimmed)
        }
        newItem = ""
    }
}
