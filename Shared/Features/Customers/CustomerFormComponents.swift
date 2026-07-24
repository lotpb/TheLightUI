//
//  CustomerFormComponents.swift
//  TheLightUI
//
//  Reusable view-builder helpers shared across CustomerForm section views.
//

import SwiftUI

// Labeled text field with consistent form styling.
@MainActor
func labeledTextField(
    _ label: String,
    placeholder: String,
    text: Binding<String>,
    keyboardType: UIKeyboardType = .default
) -> some View {
    HStack {
        Text(label)
            .formTextStyle()
        Spacer()
        TextField(placeholder, text: text)
            .formStyle()
            .keyboardType(keyboardType)
    }
}

// Combined State/Zip row with fixed-width fields.
@MainActor
func stateZipRow(state: Binding<String>, zip: Binding<String>) -> some View {
    HStack {
        Text("State:")
            .formTextStyle()
        Spacer()
        TextField("state", text: state)
            .formStyle()
            .frame(width: 50)
            .textInputAutocapitalization(.characters)
        Text("Zip:")
            .formTextStyle()
            .frame(width: 8)
            .padding(.leading, 50)
        TextField("zip", text: zip)
            .formStyle()
            .frame(maxWidth: .infinity)
            .keyboardType(.numberPad)
        Spacer()
    }
}

// Picker row bound to an index; uses Menu for reliable selected-label color control.
@MainActor
func pickerRow(
    _ title: String,
    selection: Binding<Int>,
    items: [String]
) -> some View {
    let isNone = items.indices.contains(selection.wrappedValue) && items[selection.wrappedValue].isEmpty
    let labelText = items.indices.contains(selection.wrappedValue) ? (items[selection.wrappedValue].isEmpty ? "none" : items[selection.wrappedValue]) : ""
    return HStack {
        Text(title)
            .formTextStyle()
        Spacer()
        Menu {
            ForEach(items.indices, id: \.self) { index in
                Button { selection.wrappedValue = index } label: {
                    Text(items[index].isEmpty ? "none" : items[index])
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(labelText)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
            .foregroundStyle(isNone ? Color.gray : Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Picker row with an inline pencil button to manage the list options.
@MainActor
func editablePickerRow(
    _ title: String,
    selection: Binding<Int>,
    items: [String],
    themeColor: Color,
    onEdit: @escaping () -> Void
) -> some View {
    let isNone = items.indices.contains(selection.wrappedValue) && items[selection.wrappedValue].isEmpty
    let labelText = items.indices.contains(selection.wrappedValue) ? (items[selection.wrappedValue].isEmpty ? "none" : items[selection.wrappedValue]) : ""
    return HStack {
        Text(title)
            .formTextStyle()
        Spacer()
        Menu {
            ForEach(items.indices, id: \.self) { index in
                Button { selection.wrappedValue = index } label: {
                    Text(items[index].isEmpty ? "none" : items[index])
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(labelText)
                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
            .foregroundStyle(isNone ? Color.gray : Color.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        Button(action: onEdit) {
            Image(systemName: "pencil.circle")
                .foregroundStyle(themeColor)
        }
        .buttonStyle(.plain)
    }
}

// Date row with a visually hidden label (accessible to VoiceOver via the picker label).
@MainActor
func dateRow(_ label: String, title: String, selection: Binding<Date>) -> some View {
    HStack {
        Text(label)
            .formTextStyle()
        Spacer()
        DatePicker(title, selection: selection, displayedComponents: .date)
            .labelsHidden()
    }
}

// Stepper row with an inlined text field.
// FormatStyle-based field; grouping disabled to match the previous plain-integer output.
@MainActor
func stepperRow(
    _ label: String,
    value: Binding<Int>,
    keyboardType: UIKeyboardType = .numberPad,
    increment: @escaping () -> Void,
    decrement: @escaping () -> Void
) -> some View {
    HStack {
        Text(label)
            .formTextStyle()
        Spacer()
        Stepper {
            TextField(label, value: value, format: .number.grouping(.never))
                .formStyle()
                .frame(minWidth: 80, maxWidth: 100)
                .keyboardType(keyboardType)
        } onIncrement: {
            increment()
        } onDecrement: {
            decrement()
        }
    }
}

// Segmented star-rating picker shared by employee, vendor, and misc sections.
@MainActor
func ratingRow(
    rate: Binding<String>,
    items: [String],
    themeColor: Color
) -> some View {
    HStack {
        // "Rating:" uses the accent color; only the star is yellow.
        (
            Text("Rating: ").foregroundStyle(themeColor)
            + Text(Image(systemName: "star.fill")).foregroundStyle(.yellow)
        )
        .formTextStyle()
        .imageScale(.small)

        Picker("Pick rating here", selection: rate) {
            ForEach(items, id: \.self) {
                Text($0)
            }
        }
        .pickerStyle(.segmented)
        .foregroundStyle(themeColor)
    }
}
