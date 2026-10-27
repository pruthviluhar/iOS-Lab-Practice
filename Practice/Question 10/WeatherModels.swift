
import Foundation

struct WeatherResponse: Decodable {
    let currentWeather: CurrentWeather
    let daily: DailyForecast

    enum CodingKeys: String, CodingKey {
        case currentWeather = "current_weather"
        case daily
    }

    var forecastDays: [DailyWeather] {
        let count = min(
            daily.time.count,
            min(
                daily.temperatureMax.count,
                daily.temperatureMin.count
            )
        )

        return (0..<count).map { index in
            DailyWeather(
                date: daily.time[index],
                maxTemperature: daily.temperatureMax[index],
                minTemperature: daily.temperatureMin[index]
            )
        }
    }
}

struct CurrentWeather: Decodable {
    let time: String
    let temperature: Double
    let windspeed: Double
    let winddirection: Double
    let weathercode: Int
    let isDay: Int

    enum CodingKeys: String, CodingKey {
        case time
        case temperature
        case windspeed
        case winddirection
        case weathercode
        case isDay = "is_day"
    }
}

struct DailyForecast: Decodable {
    let time: [String]
    let temperatureMax: [Double]
    let temperatureMin: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
    }
}

struct DailyWeather: Identifiable {
    let date: String
    let maxTemperature: Double
    let minTemperature: Double

    var id: String { date }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        guard let dateValue = formatter.date(from: date) else {
            return date
        }

        return dateValue.formatted(
            .dateTime.weekday(.abbreviated).month(.abbreviated).day()
        )
    }
}
