import SwiftUI

struct BillSplitter: View {
    @State private var amount = ""
    @State private var tipPercentage = 10
    @State private var customTip = 0.0
    @State private var people = 2

    var billAmount: Double {
        Double(amount) ?? 0
    }

    var tipValue: Double {
        let percentage = tipPercentage == -1
            ? customTip
            : Double(tipPercentage)

        return billAmount * percentage / 100
    }

    var totalAmount: Double {
        billAmount + tipValue
    }

    var amountPerPerson: Double {
        totalAmount / Double(people)
    }

    var hasError: Bool {
        guard let value = Double(amount) else {
            return true
        }

        return value <= 0
    }

    func currency(_ value: Double) -> String {
        value.formatted(
            .currency(
                code: Locale.current.currency?.identifier ?? "INR"
            )
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Bill Details") {
                    TextField("Enter bill amount", text: $amount)
                        .keyboardType(.decimalPad)

                    if hasError && !amount.isEmpty {
                        Text("Please enter a valid amount greater than zero.")
                            .foregroundStyle(.red)
                    }

                    Picker("Tip Percentage", selection: $tipPercentage) {
                        Text("0%").tag(0)
                        Text("10%").tag(10)
                        Text("15%").tag(15)
                        Text("20%").tag(20)
                        Text("Custom").tag(-1)
                    }
                }

                if tipPercentage == -1 {
                    Section("Custom Tip") {
                        Slider(value: $customTip, in: 0...50, step: 1)

                        Text(
                            "Custom Tip: \(customTip, specifier: "%.0f")%"
                        )
                    }
                }

                Section("Sharing") {
                    Stepper(
                        "People: \(people)",
                        value: $people,
                        in: 1...20
                    )
                }

                Section("Bill Summary") {
                    LabeledContent("Tip") {
                        Text(currency(tipValue))
                    }

                    LabeledContent("Total") {
                        Text(currency(totalAmount))
                            .fontWeight(.bold)
                    }

                    LabeledContent("Each Person Pays") {
                        Text(currency(amountPerPerson))
                            .fontWeight(.bold)
                            .foregroundStyle(.green)
                    }
                }
            }
            .navigationTitle("Bill Splitter")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        }
    }

    private func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
#endif // canImport(UIKit)
    }
}

#Preview {
    BillSplitter()
}
