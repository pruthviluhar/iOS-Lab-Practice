
import Foundation

struct QuizQuestion: Codable, Identifiable {
    let id: Int
    let question: String
    let options: [String]
    let answerIndex: Int
}

// An option keeps track of whether it is correct
// even after the options are shuffled.
struct QuizOption: Identifiable {
    let id = UUID()
    let text: String
    let isCorrect: Bool
}
