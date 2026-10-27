
import Foundation

struct Movie: Identifiable, Codable, Equatable {
    let id: Int
    let title: String
    let genre: String
    let year: Int
    var isWatched: Bool
    var rating: Int

    var validRating: Int {
        min(max(rating, 0), 5)
    }
}
