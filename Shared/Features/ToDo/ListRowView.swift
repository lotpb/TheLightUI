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
        HStack(spacing: 14) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(item.isCompleted ? Color.green : .clear)
                .background(
                    Circle().stroke(
                        AngularGradient(gradient: Gradient(colors: CustomColor.gradColors), center: .center),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                    )
                )
                .contentTransition(.symbolEffect(.replace))

            Text(item.title)
                .font(.body)
                .strikethrough(item.isCompleted, color: .secondary)
                .foregroundStyle(item.isCompleted ? .secondary : .primary)

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        ListRowView(item: ItemModel(title: "first", isCompleted: true))
        ListRowView(item: ItemModel(title: "second", isCompleted: false))
    }
}
