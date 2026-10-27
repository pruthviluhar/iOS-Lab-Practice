import Foundation

struct Contact: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var phone: String
    var email: String
    var isFavourite: Bool

    init(
        id: UUID = UUID(),
        name: String,
        phone: String,
        email: String,
        isFavourite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.isFavourite = isFavourite
    }

    var sectionLetter: String {
        guard let first = name.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).first else {
            return "#"
        }

        return first.isLetter ? String(first).uppercased() : "#"
    }
}
