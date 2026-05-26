//
//  RecenterButton.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI


struct RecenterButton: View {
    
    let onTapped: () -> Void
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            Label("Re-center", systemImage: "location.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 16)
                .frame(height: 44)
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().stroke(Color(.separator).opacity(0.16), lineWidth: 1))
                .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Recenter Button") {
    RecenterButton { }
        .padding()
}
