
import Foundation
import Combine

@MainActor
final class GitHubSearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var users: [GitHubUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: GitHubService

    init(service: GitHubService = GitHubService()) {
        self.service = service
    }

    var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func search() async {
        let searchText = trimmedQuery

        guard searchText.count >= 3 else {
            users = []
            errorMessage = nil
            isLoading = false
            return
        }

        do {
            try await Task.sleep(for: .milliseconds(500))
            try Task.checkCancellation()

            isLoading = true
            errorMessage = nil
            users = []

            let results = try await service.searchUsers(query: searchText)
            try Task.checkCancellation()

            users = results
            isLoading = false

        } catch is CancellationError {
            isLoading = false
        } catch {
            guard !Task.isCancelled else { return }

            users = []
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
