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
    @Environment(\.dismiss) private var dismiss
    private let maxWidthForIpad: CGFloat = 700
    
    private let items: [ChartItem] = [
        ChartItem(type: "Engineering", value: 100),
        ChartItem(type: "Design", value: 35),
        ChartItem(type: "Operations", value: 72),
        ChartItem(type: "Sales", value: 22),
        ChartItem(type: "Mgmt", value: 130)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ChartSection(title: "Bar", color: .red) {
                        Chart(items) { item in
                            BarMark(
                                x: .value("Department", item.type),
                                y: .value("Profit", item.value)
                            )
                            .foregroundStyle(Color.red.gradient)
                        }
                    }
                    
                    ChartSection(title: "Line", color: .blue) {
                        Chart(items) { item in
                            LineMark(
                                x: .value("Department", item.type),
                                y: .value("Profit", item.value)
                            )
                            .foregroundStyle(Color.blue.gradient)
                        }
                    }
                    
                    ChartSection(title: "Area", color: .green) {
                        Chart(items) { item in
                            AreaMark(
                                x: .value("Department", item.type),
                                y: .value("Profit", item.value)
                            )
                            .foregroundStyle(Color.green.gradient)
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: maxWidthForIpad)
            .navigationTitle("Charts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }
                }
            }
        }
    }
}

@available(iOS 16.0, *)
private struct ChartSection<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "chart.bar.xaxis")
                .font(.headline)
                .foregroundColor(color)
            
            content
                .frame(height: 220)
        }
    }
}

@available(iOS 16.0, *)
#Preview("Charts - Dark") {
    ChartView()
        .preferredColorScheme(.dark)
}
