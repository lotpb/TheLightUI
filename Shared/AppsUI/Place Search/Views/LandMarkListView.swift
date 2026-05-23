//
//  LandMarkListView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/15/22.
//

import SwiftUI


struct LandMarkListView: View {
    
    let landMarks: [LandMark]
    let index: Int
    
    var body: some View {
        List(landMarks) { landMark in
            VStack(alignment: .leading, spacing: 10) {
                Text("\(index + 1). \(landMark.name)")
                    .font(.headline)
                
                Text(landMark.title)
                    .foregroundColor(.secondary)
                
                if !landMark.displayPhone.isEmpty {
                    HStack {
                        Image(systemName: "phone")
                        Text(landMark.displayPhone)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .listStyle(.plain)
    }
}
