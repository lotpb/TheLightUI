//
//  ListRowView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 1/21/22.
//

import SwiftUI


struct ListRowView: View {
    let item : ItemModel
    var body: some View {
        
        HStack{
            Image(systemName: item.isCompleted ?  "checkmark.circle" : "circle")
                .foregroundColor(item.isCompleted ? .green : Color.clear)
                .background(Circle().stroke(AngularGradient(gradient: Gradient(colors: CustomColor.gradColors), center: .center), style: StrokeStyle(lineWidth: 1.0, lineCap: .round, lineJoin: .round)))
            
            Text(item.title)
            Spacer()
        }
        .font(.title2)//.padding()
        .padding(.vertical, 8)
    }
}

struct ListRowView_Previews: PreviewProvider {
    static var item1 = ItemModel(title: "first", isCompleted: true)
    static var item2 = ItemModel(title: "second", isCompleted: false)
    static var previews: some View {
        Group{
            ListRowView(item: item1)
            ListRowView(item: item2)
        }
        .previewLayout(.sizeThatFits)
    }
}
