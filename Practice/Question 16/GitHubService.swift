
import Foundation

enum GitHubServiceError: LocalizedError {
    case invalidURL
    case rateLimited
    case httpError(Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The search URL is invalid."
        case .rateLimited:
            return "GitHub rate limit reached. Please wait before trying again."
        case .httpError(let code):
            return "GitHub request failed (HTTP \(code))."
        case .invalidResponse:
            return "The server returned an invalid response."
        }
    }
}

struct GitHubService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func searchUsers(query: String) async throws -> [GitHubUser] {
        var components = URLComponents(
            string: "https://api.github.com/search/users"
        )
        components?.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]

        guard let url = components?.url else {
            throw GitHubServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )

        let (data, response) = try await session.data(for: request)
        try validate(response)

        return try JSONDecoder()
            .decode(GitHubSearchResponse.self, from: data)
            .items
    }

    func fetchProfile(username: String) async throws -> GitHubUserProfile {
        guard let encodedName = username.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ),
        let url = URL(
            string: "https://api.github.com/users/\(encodedName)"
        ) else {
            throw GitHubServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )

        let (data, response) = try await session.data(for: request)
        try validate(response)

        return try JSONDecoder().decode(
            GitHubUserProfile.self,
            from: data
        )
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GitHubServiceError.invalidResponse
        }

        if httpResponse.statusCode == 403 || httpResponse.statusCode == 429 {
            throw GitHubServiceError.rateLimited
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw GitHubServiceError.httpError(httpResponse.statusCode)
        }
    }
}
