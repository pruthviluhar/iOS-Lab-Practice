
import SwiftUI
import Combine

// MARK: - Screen State

enum WeatherScreenState {
    case idle
    case loading
    case success(WeatherResponse)
    case failure(String)
}

// MARK: - View Model

@MainActor
final class WeatherViewModel: ObservableObject {

    @Published var state: WeatherScreenState = .idle
    @Published var selectedCityID: String = "Ahmedabad"

    private let service = WeatherService()

    var selectedCity: WeatherCity {
        WeatherCity.cities.first {
            $0.id == selectedCityID
        } ?? WeatherCity.cities[0]
    }

    func loadWeather() async {
        state = .loading

        do {
            let result = try await service.fetchWeather(
                for: selectedCity
            )

            state = .success(result)
        } catch {
            state = .failure(
                "Unable to load weather. Check your internet connection and try again."
            )
        }
    }
}

// MARK: - Main View

struct WeatherView: View {

    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {

                    // City Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Your City")
                            .font(.headline)

                        Picker(
                            "City",
                            selection: $viewModel.selectedCityID
                        ) {
                            ForEach(WeatherCity.cities) { city in
                                Text(city.name)
                                    .tag(city.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            Color.gray.opacity(0.10),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }

                    // Screen States
                    switch viewModel.state {

                    case .idle, .loading:
                        VStack(spacing: 12) {
                            ProgressView()
                                .controlSize(.large)

                            Text("Loading weather...")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 100)

                    case .success(let weather):
                        currentWeatherCard(weather.currentWeather)

                        forecastSection(weather.forecastDays)

                    case .failure(let message):
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.exclamationmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)

                            Text("Weather Unavailable")
                                .font(.title2.bold())

                            Text(message)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)

                            Button {
                                Task {
                                    await viewModel.loadWeather()
                                }
                            } label: {
                                Label(
                                    "Retry",
                                    systemImage: "arrow.clockwise"
                                )
                                .font(.headline)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.loadWeather()
            }
            .background(Color.blue.opacity(0.04))
            .navigationTitle("Weather")
            .task(id: viewModel.selectedCityID) {
                await viewModel.loadWeather()
            }
        }
    }

    // MARK: - Current Weather Card

    private func currentWeatherCard(
        _ weather: CurrentWeather
    ) -> some View {
        VStack(spacing: 14) {

            Text(viewModel.selectedCity.name)
                .font(.title2.bold())

            Image(
                systemName: weatherSymbol(
                    code: weather.weathercode,
                    isDay: weather.isDay
                )
            )
            .symbolRenderingMode(.multicolor)
            .font(.system(size: 65))

            Text(
                "\(Int(weather.temperature.rounded()))°C"
            )
            .font(.system(size: 64, weight: .medium))
            .minimumScaleFactor(0.7)
            .lineLimit(1)

            Text(weatherDescription(weather.weathercode))
                .font(.title3)
                .foregroundStyle(.secondary)

            Label(
                "Wind: \(Int(weather.windspeed.rounded())) km/h",
                systemImage: "wind"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.18),
                    Color.cyan.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24)
        )
    }

    // MARK: - Forecast

    private func forecastSection(
        _ days: [DailyWeather]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("7-Day Forecast")
                .font(.title2.bold())

            if days.isEmpty {
                Text("No forecast data available.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(days) { day in
                        HStack(spacing: 10) {
                            Text(day.dayName)
                                .font(.subheadline)
                                .frame(
                                    width: 105,
                                    alignment: .leading
                                )

                            Image(systemName: "sun.max.fill")
                                .foregroundStyle(.orange)

                            Spacer()

                            Text(
                                "\(Int(day.minTemperature.rounded()))°"
                            )
                            .foregroundStyle(.secondary)

                            Text(
                                "\(Int(day.maxTemperature.rounded()))°"
                            )
                            .fontWeight(.semibold)
                        }
                        .padding(.vertical, 14)

                        if day.id != days.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)
                .background(
                    Color.gray.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 18)
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Weather Symbols

    private func weatherSymbol(
        code: Int,
        isDay: Int
    ) -> String {
        switch code {
        case 0:
            return isDay == 1
                ? "sun.max.fill"
                : "moon.stars.fill"
        case 1...3:
            return "cloud.sun.fill"
        case 45, 48:
            return "cloud.fog.fill"
        case 51...67, 80...82:
            return "cloud.rain.fill"
        case 71...77, 85...86:
            return "cloud.snow.fill"
        case 95...99:
            return "cloud.bolt.rain.fill"
        default:
            return "cloud.fill"
        }
    }

    // MARK: - Weather Description

    private func weatherDescription(_ code: Int) -> String {
        switch code {
        case 0:
            return "Clear Sky"
        case 1:
            return "Mainly Clear"
        case 2:
            return "Partly Cloudy"
        case 3:
            return "Overcast"
        case 45, 48:
            return "Foggy"
        case 51...55:
            return "Drizzle"
        case 56...57:
            return "Freezing Drizzle"
        case 61...65:
            return "Rain"
        case 66...67:
            return "Freezing Rain"
        case 71...77:
            return "Snowfall"
        case 80...82:
            return "Rain Showers"
        case 85...86:
            return "Snow Showers"
        case 95:
            return "Thunderstorm"
        case 96...99:
            return "Thunderstorm with Hail"
        default:
            return "Weather Conditions"
        }
    }
}

#Preview {
    WeatherView()
}
