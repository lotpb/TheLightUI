//
//  TipUI.swift
//  TheLightUI
//

import SwiftUI

struct TipUI: View {
    @State private var billAmount = 0.00
    @State private var tipPercent = 0.20
    @State private var splitCount = 1
    @FocusState private var isBillAmountFocused: Bool

    private let presetTipPercents = [0.15, 0.18, 0.20, 0.25]

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
    }

    private var tipAmount: Double {
        billAmount * tipPercent
    }

    private var totalAmount: Double {
        billAmount + tipAmount
    }

    private var amountPerPerson: Double {
        totalAmount / Double(splitCount)
    }

    var body: some View {
        List {
            totalSection
            billSection
            tipSection
            splitSection
            breakdownSection
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 72)
        }
        .navigationTitle("Tip Calculator")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isBillAmountFocused = false
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    resetCalculator()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .accessibilityLabel("Reset tip calculator")
            }
        }
    }

    private var totalSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(totalAmount, format: .currency(code: currencyCode))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }

                    Spacer()

                    Image(systemName: "receipt.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }

                HStack(spacing: 12) {
                    TipMetricView(
                        title: "Tip",
                        value: tipAmount.formatted(.currency(code: currencyCode)),
                        systemImage: "percent"
                    )
                    TipMetricView(
                        title: "Each",
                        value: amountPerPerson.formatted(.currency(code: currencyCode)),
                        systemImage: "person.2.fill"
                    )
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var billSection: some View {
        Section("Bill") {
            TextField("Bill Amount", value: $billAmount, format: .currency(code: currencyCode))
                .keyboardType(.decimalPad)
                .focused($isBillAmountFocused)
                .font(.title3.monospacedDigit())
                .onChange(of: billAmount) { newValue in
                    billAmount = max(0, newValue)
                }
        }
    }

    private var tipSection: some View {
        Section("Tip") {
            Picker("Tip Percent", selection: $tipPercent) {
                ForEach(presetTipPercents, id: \.self) { percent in
                    Text(percent, format: .percent.precision(.fractionLength(0)))
                        .tag(percent)
                }
            }
            .pickerStyle(.segmented)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("Custom", systemImage: "slider.horizontal.3")
                    Spacer()
                    Text(tipPercent, format: .percent.precision(.fractionLength(0)))
                        .font(.headline.monospacedDigit())
                }

                Slider(value: $tipPercent, in: 0...0.35, step: 0.01)
                    .tint(.green)
            }
            .padding(.vertical, 4)
        }
    }

    private var splitSection: some View {
        Section("Split") {
            Stepper(value: $splitCount, in: 1...20) {
                HStack {
                    Label("People", systemImage: "person.2")
                    Spacer()
                    Text("\(splitCount)")
                        .font(.headline.monospacedDigit())
                }
            }
        }
    }

    private var breakdownSection: some View {
        Section("Breakdown") {
            LabeledContent("Bill") {
                Text(billAmount, format: .currency(code: currencyCode))
            }

            LabeledContent("Tip") {
                Text(tipAmount, format: .currency(code: currencyCode))
            }

            LabeledContent("Total") {
                Text(totalAmount, format: .currency(code: currencyCode))
                    .fontWeight(.semibold)
            }

            LabeledContent("Per Person") {
                Text(amountPerPerson, format: .currency(code: currencyCode))
                    .fontWeight(.semibold)
            }
        }
    }

    private func resetCalculator() {
        billAmount = 0
        tipPercent = 0.20
        splitCount = 1
        isBillAmountFocused = true
    }
}

private struct TipMetricView: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.green)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline.monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.green.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview("Tip Calculator") {
    NavigationStack {
        TipUI()
    }
}
