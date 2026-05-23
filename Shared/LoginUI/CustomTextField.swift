//
//  SwiftUIView.swift
//  TheLight2
//
//  Created by Peter Balsamo on 3/17/21.
//  Copyright © 2021 Peter Balsamo. All rights reserved.
//

import SwiftUI

struct CustomTextField: View {
    enum Kind {
        case text
        case password
        case phone
    }

    // Fields
    var image: String
    var title: String
    var placeholder: String?
    @Binding var value: String

    var kind: Kind = .text
    var submitLabel: SubmitLabel = .done
    var onSubmit: (() -> Void)?

    var animation: Namespace.ID

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom) {
                Image(systemName: image)
                    .font(.system(size: 22))
                    .foregroundColor(value.isEmpty ? .secondary : .primary)
                    .frame(width: 35)

                VStack(alignment: .leading, spacing: 6) {

                    if !value.isEmpty || isFocused {
                        Text(title)
                            .font(.caption)
                            .fontWeight(.heavy)
                            .foregroundColor(.secondary)
                            .matchedGeometryEffect(id: title, in: animation)
                    }

                    ZStack(alignment: .leading) {
                        if value.isEmpty && !isFocused {
                            Text(placeholder ?? title)
                                .font(.caption)
                                .fontWeight(.heavy)
                                .foregroundColor(.secondary)
                                .matchedGeometryEffect(id: title, in: animation)
                        }

                        field
                            .focused($isFocused)
                            .submitLabel(submitLabel)
                            .onSubmit { onSubmit?() }
                    }
                }
            }

            if value.isEmpty && !isFocused {
                Divider()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color("txt").opacity(!value.isEmpty || isFocused ? 1 : 0))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(value.isEmpty && !isFocused ? 0 : 0.1), radius: 5, x: 5, y: 5)
        .shadow(color: Color.black.opacity(value.isEmpty && !isFocused ? 0 : 0.05), radius: 5, x: -5, y: -5)
        .padding(.horizontal)
        .padding(.top)
    }

    @ViewBuilder
    private var field: some View {
        switch kind {
        case .text:
            TextField("", text: $value)
                .textInputAutocapitalization(.never)
        case .password:
            SecureField("", text: $value)
        case .phone:
            TextField("", text: $value)
                .keyboardType(.numberPad)
                .textInputAutocapitalization(.never)
        }
    }
}
