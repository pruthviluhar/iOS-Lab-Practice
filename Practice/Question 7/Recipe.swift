
import Foundation

struct Recipe: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: String
    let cookTime: Int
    let difficulty: String
    let img: String
    let ingredients: [String]
    let steps: [String]
    let isVeg: Bool
}
