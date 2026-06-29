//
//  TipUI.swift
//  TheLightUI
//

import SwiftUI

/// Pure value-type model holding the tip calculation inputs and derived results.
/// Keeping the math out of the view makes it easy to reason about and test.
struct TipCalculation: Equatable {
    var bill: Double = 0
    var tipPercent: Double = 0.20
    var splitCount: Int = 1
    /// When enabled, the total is rounded up to the next whole currency unit
    /// and the tip absorbs the difference.
    var roundsTotalUp: Bool = false

    /// Total before any rounding is applied.
    private var rawTotal: Double {
        bill + bill * tipPercent
    }

    var total: Double {
        roundsTotalUp ? rawTotal.rounded(.up) : rawTotal
    }

    /// Actual tip amount. When rounding is enabled this grows so the total lands
    /// on a whole number.
    var tip: Double {
        max(0, total - bill)
    }

    var amountPerPerson: Double {
        guard splitCount > 0 else { return total }
        return total / Double(splitCount)
    }
}

struct TipUI: View {
    @State private var calculation = TipCalculation()
    @FocusState private var isBillAmountFocused: Bool

    private let presetTipPercents = [0.15, 0.18, 0.20, 0.25]

    private var currencyCode: String {
        Locale.current.currency?.identifier ?? "USD"
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

            ToolbarItem(placement: .topBarTrailing) {
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
                        Text(calculation.total, format: .currency(code: currencyCode))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .contentTransition(.numericText(value: calculation.total))
                            .animation(.snappy, value: calculation.total)
                    }

                    Spacer()

                    Image(systemName: "receipt.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }

                HStack(spacing: 12) {
                    TipMetricView(
                        title: "Tip",
                        value: calculation.tip.formatted(.currency(code: currencyCode)),
                        systemImage: "percent"
                    )
                    TipMetricView(
                        title: "Each",
                        value: calculation.amountPerPerson.formatted(.currency(code: currencyCode)),
                        systemImage: "person.2.fill"
                    )
                }
            }
            .padding(.vertical, 6)
        }
    }

    private var billSection: some View {
        Section("Bill") {
            TextField("Bill Amount", value: $calculation.bill, format: .currency(code: currencyCode))
                .keyboardType(.decimalPad)
                .focused($isBillAmountFocused)
                .font(.title3.monospacedDigit())
                .onChange(of: calculation.bill) { _, newValue in
                    if newValue < 0 {
                        calculation.bill = 0
                    }
                }
        }
    }

    private var tipSection: some View {
        Section("Tip") {
            Picker("Tip Percent", selection: $calculation.tipPercent) {
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
                    Text(calculation.tipPercent, format: .percent.precision(.fractionLength(0)))
                        .font(.headline.monospacedDigit())
                }

                Slider(value: $calculation.tipPercent, in: 0...0.35, step: 0.01)
                    .tint(.green)
            }
            .padding(.vertical, 4)
        }
    }

    private var splitSection: some View {
        Section("Split") {
            Stepper(value: $calculation.splitCount, in: 1...20) {
                HStack {
                    Label("People", systemImage: "person.2")
                    Spacer()
                    Text("\(calculation.splitCount)")
                        .font(.headline.monospacedDigit())
                }
            }

            Toggle(isOn: $calculation.roundsTotalUp) {
                Label("Round Total Up", systemImage: "arrow.up.forward")
            }
            .tint(.green)
        }
    }

    private var breakdownSection: some View {
        Section("Breakdown") {
            LabeledContent("Bill") {
                Text(calculation.bill, format: .currency(code: currencyCode))
            }

            LabeledContent("Tip") {
                Text(calculation.tip, format: .currency(code: currencyCode))
            }

            LabeledContent("Total") {
                Text(calculation.total, format: .currency(code: currencyCode))
                    .fontWeight(.semibold)
            }

            LabeledContent("Per Person") {
                Text(calculation.amountPerPerson, format: .currency(code: currencyCode))
                    .fontWeight(.semibold)
            }
        }
    }

    private func resetCalculator() {
        calculation = TipCalculation()
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
