
import Foundation

struct Product: Codable, Identifiable {
    let id: Int
    let name: String
    let category: String
    let price: Double
    let image: String
    let description: String
}
