//
//  ListRowView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI


struct ListRowView: View {
    let item: ItemModel

    var body: some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle" : "circle")
                .foregroundStyle(item.isCompleted ? Color.green : .clear)
                .background(
                    Circle().stroke(
                        AngularGradient(gradient: Gradient(colors: CustomColor.gradColors), center: .center),
                        style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round)
                    )
                )

            Text(item.title)
            Spacer()
        }
        .font(.title2)
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        ListRowView(item: ItemModel(title: "first", isCompleted: true))
        ListRowView(item: ItemModel(title: "second", isCompleted: false))
    }
}
