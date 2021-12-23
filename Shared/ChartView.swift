//
//  ChartView.swift
//  TheLightUI (iOS)
//
//  Created by Peter Balsamo on 6/10/22.
//

import SwiftUI
import Charts

struct ChartItem: Identifiable {
    var id = UUID()
    let type: String
    let value: Double
}

@available(iOS 16.0, *)
struct ChartView: View {
    @Environment(\.dismiss) var dismiss
    let maxWidthForIpad: CGFloat = 700
    
    let items: [ChartItem] = [
        ChartItem(type: "Engineering", value: 100),
        ChartItem(type: "Design", value: 35),
        ChartItem(type: "Operations", value: 72),
        ChartItem(type: "Sales", value: 22),
        ChartItem(type: "Mgmt", value: 130),
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                Chart(items) { item in
                    BarMark(x: .value("Department", item.type),
                            y: .value("Profit", item.value)
                    )
                    .foregroundStyle(Color.red.gradient)
                }
                .frame(height: 200)
                .padding()
                
                Chart(items) { item in
                    LineMark(x: .value("Department", item.type),
                            y: .value("Profit", item.value)
                    )
                    .foregroundStyle(Color.blue.gradient)
                }
                .frame(height: 200)
                .padding()
                
                Chart(items) { item in
                    AreaMark(x: .value("Department", item.type),
                            y: .value("Profit", item.value)
                    )
                    .foregroundStyle(Color.green.gradient)
                }
                .frame(height: 200)
                .padding()
                
            }
            .frame(maxWidth: maxWidthForIpad)
            .navigationTitle("Charts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }
                }
            }
        }
        
    }
}

@available(iOS 16.0, *)
struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView().preferredColorScheme(.dark)
    }
}
