
import Foundation
import Combine

@MainActor
final class DestinationStore: ObservableObject {
    @Published private(set) var destinations: [Destination] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var likedDestinations: [Destination] = []
    @Published private(set) var errorMessage: String?

    private struct HistoryItem {
        let destination: Destination
        let wasLiked: Bool
    }

    private var history: [HistoryItem] = []

    init() {
        loadDestinations()
    }

    var currentDestination: Destination? {
        guard currentIndex < destinations.count else { return nil }
        return destinations[currentIndex]
    }

    var isFinished: Bool {
        !destinations.isEmpty && currentIndex >= destinations.count
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    func loadDestinations() {
        guard let url = Bundle.main.url(
            forResource: "destinations",
            withExtension: "json"
        ) else {
            errorMessage = "destinations.json was not found."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            destinations = try JSONDecoder().decode(
                [Destination].self,
                from: data
            )
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load destinations: \(error.localizedDescription)"
        }
    }

    func decide(like: Bool) {
        guard let destination = currentDestination else { return }

        history.append(
            HistoryItem(destination: destination, wasLiked: like)
        )

        if like {
            likedDestinations.append(destination)
        }

        currentIndex += 1
    }

    func undo() {
        guard let last = history.popLast() else { return }

        currentIndex = max(0, currentIndex - 1)

        if last.wasLiked,
           let index = likedDestinations.lastIndex(of: last.destination) {
            likedDestinations.remove(at: index)
        }
    }
}
