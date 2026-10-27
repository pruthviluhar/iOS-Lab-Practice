
import SwiftUI
import Foundation

struct UnitConverterView: View {

    @State private var category: ConversionCategory = .length
    @State private var inputValue = "1"
    @State private var fromUnit: ConverterUnit = .meters
    @State private var toUnit: ConverterUnit = .kilometers
    @State private var recentConversions: [String] = []
    @State private var rotationAngle = 0.0

    // MARK: - Categories

    enum ConversionCategory: String, CaseIterable, Identifiable {
        case length = "Length"
        case temperature = "Temperature"
        case weight = "Weight"
        case time = "Time"

        var id: String { rawValue }

        var units: [ConverterUnit] {
            ConverterUnit.allCases.filter { $0.category == self }
        }
    }

    // MARK: - Units

    enum ConverterUnit: String, CaseIterable, Identifiable {
        case meters = "Meters"
        case kilometers = "Kilometers"
        case miles = "Miles"
        case feet = "Feet"

        case celsius = "Celsius"
        case fahrenheit = "Fahrenheit"
        case kelvin = "Kelvin"

        case grams = "Grams"
        case kilograms = "Kilograms"
        case pounds = "Pounds"
        case ounces = "Ounces"

        case seconds = "Seconds"
        case minutes = "Minutes"
        case hours = "Hours"
        case days = "Days"

        var id: String { rawValue }

        var category: ConversionCategory {
            switch self {
            case .meters, .kilometers, .miles, .feet:
                return .length

            case .celsius, .fahrenheit, .kelvin:
                return .temperature

            case .grams, .kilograms, .pounds, .ounces:
                return .weight

            case .seconds, .minutes, .hours, .days:
                return .time
            }
        }
    }

    // MARK: - Custom Day Unit

    private static let daysUnit = UnitDuration(
        symbol: "d",
        converter: UnitConverterLinear(coefficient: 86400)
    )

    // MARK: - Input

    private var numericInput: Double? {
        guard let value = Double(inputValue),
              value.isFinite else {
            return nil
        }

        return value
    }

    // MARK: - Conversion

    private var convertedValue: Double? {
        guard let value = numericInput else {
            return nil
        }

        switch category {

        case .length:
            let source: UnitLength
            let target: UnitLength

            switch fromUnit {
            case .meters: source = .meters
            case .kilometers: source = .kilometers
            case .miles: source = .miles
            case .feet: source = .feet
            default: return nil
            }

            switch toUnit {
            case .meters: target = .meters
            case .kilometers: target = .kilometers
            case .miles: target = .miles
            case .feet: target = .feet
            default: return nil
            }

            return Measurement(value: value, unit: source)
                .converted(to: target).value

        case .temperature:
            let source: UnitTemperature
            let target: UnitTemperature

            switch fromUnit {
            case .celsius: source = .celsius
            case .fahrenheit: source = .fahrenheit
            case .kelvin: source = .kelvin
            default: return nil
            }

            switch toUnit {
            case .celsius: target = .celsius
            case .fahrenheit: target = .fahrenheit
            case .kelvin: target = .kelvin
            default: return nil
            }

            return Measurement(value: value, unit: source)
                .converted(to: target).value

        case .weight:
            let source: UnitMass
            let target: UnitMass

            switch fromUnit {
            case .grams: source = .grams
            case .kilograms: source = .kilograms
            case .pounds: source = .pounds
            case .ounces: source = .ounces
            default: return nil
            }

            switch toUnit {
            case .grams: target = .grams
            case .kilograms: target = .kilograms
            case .pounds: target = .pounds
            case .ounces: target = .ounces
            default: return nil
            }

            return Measurement(value: value, unit: source)
                .converted(to: target).value

        case .time:
            let source: UnitDuration
            let target: UnitDuration

            switch fromUnit {
            case .seconds: source = .seconds
            case .minutes: source = .minutes
            case .hours: source = .hours
            case .days: source = Self.daysUnit
            default: return nil
            }

            switch toUnit {
            case .seconds: target = .seconds
            case .minutes: target = .minutes
            case .hours: target = .hours
            case .days: target = Self.daysUnit
            default: return nil
            }

            return Measurement(value: value, unit: source)
                .converted(to: target).value
        }
    }

    // MARK: - Formatted Result

    private var formattedResult: String {
        guard let result = convertedValue,
              result.isFinite else {
            return "Enter a valid number"
        }

        return result.formatted(
            .number.precision(.fractionLength(0...6))
        )
    }

    private var conversionDescription: String? {
        guard let result = convertedValue,
              result.isFinite else {
            return nil
        }

        let formatted = result.formatted(
            .number.precision(.fractionLength(0...6))
        )

        return "\(inputValue) \(fromUnit.rawValue) = \(formatted) \(toUnit.rawValue)"
    }

    // MARK: - User Interface

    var body: some View {
        NavigationStack {
            Form {

                Section("Category") {
                    Picker("Convert", selection: $category) {
                        ForEach(ConversionCategory.allCases) { item in
                            Text(item.rawValue)
                                .tag(item)
                        }
                    }
                    .onChange(of: category) {
                        updateUnitsForCategory()
                    }
                }

                Section("From") {
                    TextField("Enter value", text: $inputValue)
                        .keyboardType(.decimalPad)

                    Picker("From Unit", selection: $fromUnit) {
                        ForEach(category.units) { unit in
                            Text(unit.rawValue)
                                .tag(unit)
                        }
                    }
                }

                Section {
                    HStack {
                        Spacer()

                        Button {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                swapUnits()
                                rotationAngle += 180
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.title2)
                                .rotationEffect(
                                    .degrees(rotationAngle)
                                )
                                .padding(12)
                                .background(
                                    Color.blue.opacity(0.12),
                                    in: Circle()
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Swap units")

                        Spacer()
                    }
                }

                Section("To") {
                    Picker("To Unit", selection: $toUnit) {
                        ForEach(category.units) { unit in
                            Text(unit.rawValue)
                                .tag(unit)
                        }
                    }

                    HStack {
                        Text("Result")
                        Spacer()

                        Text(formattedResult)
                            .font(.title3.bold())
                            .foregroundStyle(.blue)
                    }

                    if convertedValue != nil {
                        Text(toUnit.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Recent Conversions") {
                    if recentConversions.isEmpty {
                        Text("Your recent conversions appear here.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(
                            Array(recentConversions.enumerated()),
                            id: \.offset
                        ) { _, conversion in
                            Text(conversion)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .navigationTitle("Unit Converter")
            .onChange(of: conversionDescription) {
                addRecentConversion()
            }
        }
    }

    // MARK: - Swap Units

    private func swapUnits() {
        let previousResult = convertedValue
        let oldFromUnit = fromUnit

        fromUnit = toUnit
        toUnit = oldFromUnit

        if let previousResult {
            inputValue = String(previousResult)
        }
    }

    // MARK: - Update Units

    private func updateUnitsForCategory() {
        let units = category.units

        guard let firstUnit = units.first else {
            return
        }

        fromUnit = firstUnit
        toUnit = units.count > 1 ? units[1] : firstUnit
    }

    // MARK: - Recent Conversions

    private func addRecentConversion() {
        guard let description = conversionDescription else {
            return
        }

        guard recentConversions.first != description else {
            return
        }

        recentConversions.removeAll {
            $0 == description
        }

        recentConversions.insert(description, at: 0)

        if recentConversions.count > 5 {
            recentConversions = Array(
                recentConversions.prefix(5)
            )
        }
    }
}

#Preview {
    UnitConverterView()
}
