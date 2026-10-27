
import Foundation

struct WeatherCity: Identifiable {
    let name: String
    let latitude: Double
    let longitude: Double

    var id: String { name }

    static let cities: [WeatherCity] = [
        WeatherCity(
            name: "Ahmedabad",
            latitude: 23.02,
            longitude: 72.57
        ),
        WeatherCity(
            name: "Mumbai",
            latitude: 19.08,
            longitude: 72.88
        ),
        WeatherCity(
            name: "New Delhi",
            latitude: 28.61,
            longitude: 77.21
        ),
        WeatherCity(
            name: "Bengaluru",
            latitude: 12.97,
            longitude: 77.59
        ),
        WeatherCity(
            name: "Chennai",
            latitude: 13.08,
            longitude: 80.27
        )
    ]
}

enum WeatherError: LocalizedError {
    case invalidURL
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The weather URL is invalid."

        case .invalidResponse:
            return "The weather server returned an invalid response."
        }
    }
}

struct WeatherService {

    func fetchWeather(
        for city: WeatherCity
    ) async throws -> WeatherResponse {

        var components = URLComponents(
            string: "https://api.open-meteo.com/v1/forecast"
        )

        components?.queryItems = [
            URLQueryItem(
                name: "latitude",
                value: String(city.latitude)
            ),
            URLQueryItem(
                name: "longitude",
                value: String(city.longitude)
            ),
            URLQueryItem(
                name: "current_weather",
                value: "true"
            ),
            URLQueryItem(
                name: "daily",
                value: "temperature_2m_max,temperature_2m_min"
            ),
            URLQueryItem(
                name: "timezone",
                value: "auto"
            ),
            URLQueryItem(
                name: "forecast_days",
                value: "7"
            )
        ]

        guard let url = components?.url else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw WeatherError.invalidResponse
        }

        return try JSONDecoder().decode(
            WeatherResponse.self,
            from: data
        )
    }
}
