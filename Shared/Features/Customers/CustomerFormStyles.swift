//
//  CustomerFormStyles.swift
//  TheLightUI
//

import SwiftUI

// Shared label width — keep in sync with CustomerFormUI.Layout.labelWidth.
private let formLabelWidth: CGFloat = 100

// Common text field styling for the form.
extension TextField {
    func formStyle() -> some View {
        self
            .font(.system(size: 20.0))
            // Color.primary (not the hierarchical .primary) so the field
            // text uses the adaptive label color, not the inherited theme tint.
            .foregroundStyle(Color.primary)
            .frame(minWidth: 50, maxWidth: .infinity)
            .multilineTextAlignment(.leading)
            .textInputAutocapitalization(.sentences)
            .clipShape(.rect(cornerRadius: 10))
    }
}

// Common label and picker text styling used throughout the form.
extension Text {
    func formTextStyle() -> some View {
        self
            .font(.system(size: 18.0))
            .bold()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .frame(width: formLabelWidth, alignment: .leading)
            .textSelection(.enabled)
    }

    func pickerTextStyle() -> some View {
        self
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}
