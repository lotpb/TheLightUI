//
//  CustomerFormUI.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 12/22/21.
//

// Customer data entry form with profile, contact info, job details, and misc fields.

import SwiftUI

///
// CustomerFormUI
// Presents a multi-section form for creating or editing a customer record.
// Uses a view model to manage form state, validation, and persistence.
///
struct CustomerFormUI: View {
    // Layout constants for sizing fields and controls.
    enum Layout {
        static let avatarSize: CGFloat = 75
        static let labelWidth: CGFloat = 100
        static let stateFieldWidth: CGFloat = 50
        static let zipLabelWidth: CGFloat = 8
        static let zipLabelLeadingPadding: CGFloat = 50
        static let stepperFieldMinWidth: CGFloat = 80
        static let stepperFieldMaxWidth: CGFloat = 100
    }

    // Persisted theme color choice.
    @AppStorage("color") private var color: Int?
    // Shared picklist values used by multiple pickers.
    @Environment(PickerDataModel.self) private var pickerviewModel
    // Dismiss action from the environment.
    @Environment(\.dismiss) private var dismiss
    // Controls initial focus to the first name field.
    @FocusState private var firstNameInFocus: Bool

    // View model that holds all form data and business logic.
    @State private var viewModel: CustomerFormViewModel
    // Which editable picker sheet is open (nil = none).
    @State private var managingPickerType: PickerType? = nil

    private var themeColor: Color {
        AppTheme.accentColor(for: color)
    }

    // Initialize the view model and configure UISegmentedControl appearance.
    init(
        detail: CustomerItem,
        createDate: Date,
        startDate: Date,
        completeDate: Date,
        mode: CustomerFormMode,
        formService: CustomerFormServicing = FirebaseCustomerFormService()
    ) {
        _viewModel = State(
            initialValue: CustomerFormViewModel(
                detail: detail,
                createDate: createDate,
                startDate: startDate,
                completeDate: completeDate,
                mode: mode,
                formService: formService
            )
        )

        // Configure the global segmented-control appearance exactly once,
        // rather than on every initialization of this view.
        Self.configureSegmentedControlAppearance
    }

    // Lazily-initialized once on first access; SwiftUI has no native API for a
    // segmented picker's selected-segment tint, so the UIKit proxy is still required.
    private static let configureSegmentedControlAppearance: Void = {
        UISegmentedControl.appearance().selectedSegmentTintColor = .lightGray
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
    }()

    var body: some View {
        NavigationStack {
            Form {
                CustomerFormProfileSection(viewModel: viewModel, firstNameInFocus: $firstNameInFocus)
                CustomerFormCategorySection(viewModel: viewModel)
                CustomerFormContactSection(viewModel: viewModel)
                CustomerFormJobSection(viewModel: viewModel, managingPickerType: $managingPickerType)
                CustomerFormMiscSection(viewModel: viewModel, managingPickerType: $managingPickerType)
            }
            .font(.system(size: 20.0))
            .onAppear(perform: loadFormState)
            // Picker list management sheet — shown when a pencil button is tapped.
            .sheet(item: $managingPickerType) { pickerType in
                PickerManagementSheet(pickerType: pickerType, model: pickerviewModel)
            }
            .navigationTitle("Data Entry")
            .toolbar { toolbarContent }
            .foregroundStyle(themeColor)
            // Success alert displayed after saving.
            .alert("Success", isPresented: $viewModel.showAlertUpdate) {
                Button("Ok") { dismiss() }
            } message: {
                Text("Record updated successfully")
            }
        }
        // Accent/tint color for controls.
        .tint(themeColor)
    }

    // Toolbar actions: Close (dismiss) and Save (via view model).
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button { dismiss() } label: {
                Label("Close", systemImage: "xmark.circle")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            // Disabled until the view model deems the form valid.
            Button { viewModel.saveButtonTapped() } label: {
                Text("Save").fontWeight(.bold)
            }
            .disabled(viewModel.isButtonDisabled)
        }
    }

    // Initialize form values and optionally request focus on the first name field after a short delay.
    private func loadFormState() {
        viewModel.loadFormState()
        guard viewModel.shouldFocusFirstName else { return }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            guard !Task.isCancelled else { return }
            firstNameInFocus = true
            viewModel.consumeFirstNameFocusRequest()
        }
    }
}

// Preview: form in dark mode with sample environment objects.
#Preview("Form - Dark") {
    NavigationStack {
        CustomerFormUI(
            detail: .emptyCustomer,
            createDate: Date(),
            startDate: Date(),
            completeDate: Date(),
            mode: .new,
            formService: PreviewCustomerFormService()
        )
        .environment(CustomerStore(customerService: PreviewCustomerService()))
        .environment(PickerDataModel())
    }
    .preferredColorScheme(.dark)
}
