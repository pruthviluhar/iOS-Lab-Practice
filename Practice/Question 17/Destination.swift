
import Foundation

struct Destination: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let country: String
    let description: String
    let emoji: String
}
